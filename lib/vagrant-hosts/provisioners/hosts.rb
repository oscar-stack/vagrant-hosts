require 'vagrant'
require 'vagrant-hosts/ssh' # Guerrilla patch ssh download
require 'tempfile'

module VagrantHosts; end

class VagrantHosts::Provisioner < Vagrant::Provisioners::Base

  class Config < Vagrant::Config::Base

    attr_reader :hosts

    def initialize
      @hosts = []
    end

    def add_host(address, aliases)
      @hosts << [address, aliases]
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

    def hosts_format
      @config.hosts.inject('') do |str, (address, aliases)|
        str << "#{address} #{aliases.join(' ')}\n"
      end
    end
  end
end
