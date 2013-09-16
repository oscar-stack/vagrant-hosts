# Provide an abstract base class for syncing hosts entries
class VagrantHosts::Cap::SyncHosts::Base

  def self.sync_hosts(machine, config)
    new(machine, config)
  end

  def initialize(machine, config)
    @machine, @config = machine, config
    @env = @machine.env
  end

  def sync!
    hostname = @machine.config.vm.hostname || @machine.name.to_s
    change_host_name(hostname)

    # call to method not implemented by abstract base class
    update_hosts
  end

  private

  # @param name [String] The new hostname to apply on the guest
  def change_host_name(name)
    case Vagrant::VERSION
    when /^1\.1/
      @machine.guest.change_host_name(name)
    when /^1\.2/, /^1\.3/
      @machine.guest.capability(:change_host_name, name)
    else
      raise UnknownVersion, :vagrant_version => Vagrant::VERSION
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

  # Builds an array containing hostname and aliases for a given machine.
  def hostnames_for_machine machine
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

  def local_hosts
    [
      ['127.0.0.1', ['localhost']],
      ['127.0.1.1', hostnames_for_machine(@machine)],
    ]
  end

  def vagrant_hosts
    hosts = []

    all_machines.each do |m|
      m.config.vm.networks.each do |(net_type, opts)|
        next unless net_type == :private_network
        addr = opts[:ip]
        hosts << [addr, hostnames_for_machine(m)]
      end
    end

    hosts
  end

  # @return [Array<Vagrant::Machine>]
  def all_machines
    @env.active_machines.map { |vm_id| @env.machine(*vm_id) }
  end

end
