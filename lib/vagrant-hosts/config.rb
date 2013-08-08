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

  def initialize
    @hosts = []
    @autoconfigure = UNSET_VALUE
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
     if  @hosts.empty?
        @autoconfigure = true
      else
        @autoconfigure = false
      end
    end
  end

  # @param other [VagrantHosts::Config]
  # @return [VagrantHosts::Config] The merged results
  def merge(other)
    super.tap do |result|
      result.hosts += other.hosts
    end
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
