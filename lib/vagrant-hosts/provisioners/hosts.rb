require 'vagrant'
require 'vagrant-hosts'
require 'vagrant-hosts/ssh' # Guerrilla patch ssh download
require 'vagrant-hosts/config'
require 'tempfile'


class VagrantHosts::Provisioner < Vagrant::Provisioners::Base

  def self.config_class
    ::VagrantHosts::Config
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
      upload_tmphosts
      atomic_sync
    end

    def upload_tmphosts
      cache = Tempfile.new('tmp-hosts')
      cache.write(format_hosts)
      cache.flush
      @env[:vm].channel.upload(cache.path, '/tmp/hosts')
    end

    def atomic_sync
      script = <<-ATOMIC
hostname #{@env[:vm].name}
domainname vagrantup.internal
install -m 644 /tmp/hosts /etc/hosts
      ATOMIC

      sync = Tempfile.new('sync')
      sync.write(script)
      sync.flush
      @env[:vm].channel.upload(sync.path, '/tmp/sync')

      @env[:vm].channel.sudo('bash /tmp/sync')
    end

    # Generates content appropriate for a linux hosts file
    #
    # @return [String] All hosts in the config joined into hosts records
    def format_hosts
      @config.hosts.inject('') do |str, (address, aliases)|
        str << "#{address} #{aliases.join(' ')}\n"
      end
    end
  end
end
