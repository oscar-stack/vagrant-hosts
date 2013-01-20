require 'vagrant'
require 'vagrant-hosts'

class VagrantHosts::Config < Vagrant::Config::Base

  attr_reader :hosts

  def initialize
    @hosts = []
  end

  # Register a host for entry
  #
  # @param [String] address The IP address for aliases
  # @param [Array] aliases An array of hostnames to assign to the IP address
  def add_host(address, aliases)
    @hosts << [address, aliases]
  end

  def add_ipv6_multicast
    add_host '::1',     ['ip6-localhost', 'ip6-loopback']
    add_host 'fe00::0', ['ip6-localnet']
    add_host 'ff00::0', ['ip6-mcastprefix']
    add_host 'ff02::1', ['ip6-allnodes']
    add_host 'ff02::2', ['ip6-allrouters']
  end

  def validate(env, errors)
    @hosts.each do |(address, aliases)|
      unless aliases.is_a? Array
        errors.add("#{address} should have an array of aliases, got #{aliases.inspect}:#{aliases.class}")
      end
    end
  end
end
