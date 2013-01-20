require 'vagrant'
require 'vagrant-hosts'
require 'vagrant-hosts/ssh' # Guerrilla patch ssh download
require 'tempfile'


class VagrantHosts::Provisioner < Vagrant::Provisioners::Base

  class Config < Vagrant::Config::Base

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

  def self.config_class
    Config
  end

  def provision!
    # too tired to do this. detect target platform, select according provider,
    # add entries that are specified in the config and are not on the client

    driver = Linux.new(@env, config)
    driver.sync!
  end

  class Linux

    def initialize(env, config)
      @env, @config = env, config
    end

    def sync!
      cache = Tempfile.new('vagrant-hosts')

      # It would be really cool to synchronize this file instead of blindly
      # smashing the remote hosts file, but this is the quick and dirty solution.
      #@env[:vm].channel.download('/etc/hosts', cache.path)
      #cache.rewind
      #cache.truncate(0)

      cache.write hosts_format
      cache.flush

      @env[:vm].channel.upload(cache.path, '/tmp/hosts')
      @env[:vm].channel.sudo('install -m 644 /tmp/hosts /etc/hosts')
    end

    # Generates content appropriate for a linux hosts file
    #
    # @return [String] All hosts in the config joined into hosts records
    def hosts_format
      @config.hosts.inject('') do |str, (address, aliases)|
        str << "#{address} #{aliases.join(' ')}\n"
      end
    end
  end
end
