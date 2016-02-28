require 'vagrant'

module VagrantHosts
  class Config < Vagrant.plugin('2', :config)

    # @!attribute hosts
    #   @return [Array<Array<String, Array<String>>>] A list of IP addresses and their aliases
    attr_reader :hosts

    # @!attribute autoconfigure
    #   @return [TrueClass, FalseClass] If hosts should be generated from the
    #                                   other vagrant machines
    attr_accessor :autoconfigure

    # @!attribute add_localhost_hostnames
    #   @return [TrueClass, FalseClass] A boolean indicating whether a
    #     `127.0.1.1` entry should be added mapping to the FQDN of the VM.
    #     Default: `true`.
    attr_accessor :add_localhost_hostnames

    # @!attribute sync_hosts
    #   @return [TrueClass, FalseClass] When set to true, running the hosts
    #     provisioner on this VM will update all other running machines that
    #     use the hosts provisioner. This action will also occur on machine
    #     destruction. Defaults to `false`.
    attr_accessor :sync_hosts

    # @!attribute [rw] exports
    #   @return [Hash{String => Array<Array<String, Array<String>>>}]
    #     A hash containing named lists of `[address, [aliases]]` tuples
    #     that are exported by this VM. These exports can be collected by other
    #     VMs using the {#imports} option.
    attr_accessor :exports

    # @!attribute [rw] imports
    #   @return [Array<String>]
    #     A list of exports to collect from other VMs.
    attr_accessor :imports

    def initialize
      @hosts = []
      @exports = {}
      @imports = []
      @autoconfigure = UNSET_VALUE
      @add_localhost_hostnames = UNSET_VALUE
      @sync_hosts = UNSET_VALUE
    end

    # Register a host for entry
    #
    # @param [String] address The IP address for aliases
    # @param [Array] aliases An array of hostnames to assign to the IP address
    def add_host(address, aliases)
      @hosts << [address, aliases]
    end

    # All IPv6 multicast addresses
    def add_ipv6_multicast
      add_host '::1',     ['ip6-localhost', 'ip6-loopback']
      add_host 'fe00::0', ['ip6-localnet']
      add_host 'ff00::0', ['ip6-mcastprefix']
      add_host 'ff02::1', ['ip6-allnodes']
      add_host 'ff02::2', ['ip6-allrouters']
    end

    def finalize!
      if @autoconfigure == UNSET_VALUE
       if  @hosts.empty? && @imports.empty?
          @autoconfigure = true
        else
          @autoconfigure = false
        end
      end

      if @add_localhost_hostnames == UNSET_VALUE
        @add_localhost_hostnames = true
      end

      @sync_hosts = false if @sync_hosts == UNSET_VALUE
    end

    # @param other [VagrantHosts::Config]
    # @return [VagrantHosts::Config] The merged results
    def merge(other)
      result = super
      result.instance_variable_set(:@hosts, self.hosts.dup + other.hosts.dup)

      result
    end

    def validate(machine)
      errors = []
      @hosts.each do |(address, aliases)|
        unless aliases.is_a? Array
          errors << "#{address} should have an array of aliases, got #{aliases.inspect}:#{aliases.class}"
        end
      end

      {"Vagrant Hosts" => errors}
    end
  end
end
