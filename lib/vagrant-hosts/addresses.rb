module VagrantHosts::Addresses

  private

  def all_hosts(config)

    all_hosts = []
    all_hosts += local_hosts(@machine)

    if config.autoconfigure
      all_hosts += vagrant_hosts(@env)
    end
    all_hosts += config.hosts

    all_hosts
  end

  # Builds an array containing hostname and aliases for a given machine.
  def hostnames_for_machine(machine)
    # Cast any Symbols to Strings
    machine_name = machine.name.to_s
    hostname = machine.config.vm.hostname || machine_name

    hostnames = [hostname]
    # If the hostname is a fqdn, add the first component as an alias.
    hostnames << hostname.split('.').first if hostname.index('.')
    # Also add the machine name as an alias.
    hostnames << machine_name unless hostnames.include? machine_name

    hostnames
  end

  def local_hosts(machine)
    [
      ['127.0.0.1', ['localhost']],
    ]
  end

  def vagrant_hosts(env)
    hosts = []

    all_machines(env).each do |m|
      m.config.vm.networks.each do |(net_type, opts)|
        next unless net_type == :private_network
        addr = opts[:ip]
        hosts << [addr, hostnames_for_machine(m)]
      end
    end

    hosts
  end

  # @return [Array<Vagrant::Machine>]
  def all_machines(env)
    env.active_machines.map { |vm_id| env.machine(*vm_id) }
  end

end
