require 'vagrant'
require 'tempfile'


module VagrantHosts
class Provisioner < Vagrant.plugin('2', :provisioner)

  def initialize(machine, config)
    @machine, @config = machine, config
    p
  end

  def provision
    # too tired to do this. detect target platform, select according provider,
    # add entries that are specified in the config and are not on the client

    driver = Linux.new(@machine, @config)
    driver.sync!
  end

  class Linux

    def initialize(machine, config)
      @machine, @config = machine, config
    end

    def sync!
      upload_tmphosts
      atomic_sync
    end

    def upload_tmphosts
      cache = Tempfile.new('tmp-hosts')
      cache.write(format_hosts)
      cache.flush
      @machine.communicate.upload(cache.path, '/tmp/hosts')
    end

    def atomic_sync
      script = <<-ATOMIC
hostname #{@machine.name}
domainname vagrantup.internal
install -m 644 /tmp/hosts /etc/hosts
      ATOMIC

      sync = Tempfile.new('sync')
      sync.write(script)
      sync.flush
      @machine.communicate.upload(sync.path, '/tmp/sync')

      @machine.communicate.sudo('bash /tmp/sync')
    end

    # Generates content appropriate for a linux hosts file
    #
    # @return [String] All hosts in the config joined into hosts records
    def format_hosts
      all_hosts = @config.hosts
      all_hosts.unshift(['127.0.0.1', ['localhost']])
      all_hosts.unshift(['127.0.1.1', [@machine.name]])


      all_hosts.inject('') do |str, (address, aliases)|
        str << "#{address} #{aliases.join(' ')}\n"
      end
    end
  end
end
end
