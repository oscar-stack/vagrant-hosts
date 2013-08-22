class VagrantHosts::Provisioner::Linux

  include VagrantHosts::Provisioner::Hostname

  def initialize(machine, config)
    @machine, @config = machine, config

    @env = @machine.env
  end

  def sync!
    upload_tmphosts
    update_hosts
  end

  private

  def upload_tmphosts
    cache = Tempfile.new('tmp-hosts')
    cache.write(format_hosts)
    cache.flush
    @machine.communicate.upload(cache.path, '/tmp/hosts')
  end

  def update_hosts
    hostname = @machine.config.vm.hostname || @machine.name.to_s
    change_host_name(hostname)
    @machine.communicate.sudo('install -m 644 /tmp/hosts /etc/hosts')
  end

  # Generates content appropriate for a linux hosts file
  #
  # @return [String] All hosts in the config joined into hosts records
  def format_hosts
    all_hosts.inject('') do |str, (address, aliases)|
      str << "#{address} #{aliases.join(' ')}\n"
    end
  end

  def all_hosts
    all_hosts = []
    all_hosts += local_hosts

    if @config.autoconfigure
      all_hosts += vagrant_hosts
    end
    all_hosts += @config.hosts

    all_hosts
  end

  def local_hosts
    hostname = @machine.config.vm.hostname
    hostname ||= @machine.name # Fall back if hostname is unset.

    [
      ['127.0.0.1', ['localhost']],
      ['127.0.1.1', [hostname]],
    ]
  end

  def vagrant_hosts
    hosts = []

    all_machines.each do |m|
      m_networks = m.config.vm.networks
      m_hostname = m.config.vm.hostname

      m_networks.each do |(net_type, opts)|
        next unless net_type == :private_network
        addr = opts[:ip]
        hosts << [addr, [m.name, m_hostname]]
      end
    end

    hosts
  end

  # @return [Array<Vagrant::Machine>]
  def all_machines
    @env.active_machines.map { |vm_id| @env.machine(*vm_id) }
  end
end
