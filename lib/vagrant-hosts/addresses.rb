require 'resolv'
require 'ipaddr'

module VagrantHosts::Addresses

  private

  def all_hosts(config)
    all_hosts = []
    all_hosts += local_hosts(@machine, config)

    if config.autoconfigure
      all_hosts += vagrant_hosts(@env)
    end

    unless config.imports.empty?
      all_hosts += collect_imports(@machine, config)
    end

    all_hosts += config.hosts

    all_hosts.uniq
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

  def local_hosts(machine, config)
    entries = [['127.0.0.1', ['localhost']]]

    if config.add_localhost_hostnames
      entries << ['127.0.1.1', hostnames_for_machine(machine)]
    end

    entries
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

  # Collect all hosts entries for a machine
  #
  # @param machine [Vagrant::Machine] A vagrant VM to perform collection upon.
  # @param config [VagrantHosts::Config] A configuration object for the hosts
  #   provisioner.
  #
  # @return [Array<Array<IPAddr, Array<String>>>] A list of address, alias
  #   tuples.
  def collect_imports(machine, config)
    env = machine.env
    imports = config.imports

    # TODO: Use Set?
    hosts = []

    all_machines(env).each do |m|
      next if m.name == machine.name

      m.config.vm.provisioners.each do |p|
        next unless (p.type.intern == :hosts)

        imports.each do |k|
          next unless p.config.exports.has_key?(k)
          hosts.concat resolve_host_entries(p.config.exports[k], m)
        end
      end
    end

    hosts.uniq
  end

  # Generate a list of IP addresses and aliases for a vagrant machine
  #
  # This functionresolves a list of addresses and aliases, possibly including
  # special keys, into a list of addresses and aliases.
  #
  # See {#resolve_addresses} and {#resolve_aliases} for special key handling.
  #
  # @param entries[Array<String, Array<String>>] A list of entries.
  #
  # @raise [IPAddr::InvalidAddressError] Raised when an invalid address is
  #   supplied.
  # @raise [Resolv::ResolvError] When a hostname cannot be resolved to an IP.
  #
  # @return [Array<IPAddr, Array<String>>]
  def resolve_host_entries(entries, machine)
    entries.flat_map do |(address, aliases)|
      names = resolve_aliases(aliases, machine)
      resolve_addresses(address, machine).map {|ip| [resolve_ip(ip), names]}
    end
  end

  # Generate a list of IP addresses for a vagrant machine
  #
  # This function resolves an address or special key into a list of
  # IP addresses.
  #
  # Special keys currently supported:
  #
  #   - `@vagrant_private_networks`: The IP addresses of each privte network
  #     attached to the machine.
  #
  #   - `@vagrant_ssh`: The IP address used by Vagrant to communicate with the
  #     machine (also includes WinRM and other communicators).
  #
  # @param aliases [String] An IP address or special key.
  # @param machine [Vagrant::Machine] The Vagrant machine to use when resolving
  #   addresses.
  #
  # @return [Array<String>] A list of addresses.
  def resolve_addresses(address, machine)
    ips = case address
    when '@vagrant_private_networks'
      machine.config.vm.networks.map do |(net_type, opts)|
        next unless net_type == :private_network
        opts[:ip]
      end.compact
    when '@vagrant_ssh'
      if machine.ssh_info
        machine.ssh_info[:host]
      else
        []
      end
    else
      address
    end

    Array(ips)
  end

  # Generate an list of IP addresses from a string
  #
  # This function resolves a string into an IP address.
  # IP addresses.
  #
  # @param address [String] A string that might be an IP address or a hostname.
  #
  # @raise [IPAddr::InvalidAddressError] Raised when an invalid address is
  #   supplied.
  # @raise [Resolv::ResolvError] When a hostname cannot be resolved to an IP.
  #
  # @return [IPAddr] An IP address.
  def resolve_ip(address)
    ip = begin
      IPAddr.new(address)
    rescue IPAddr::InvalidAddressError
      # Wasn't an IP address. Resolve it. The AWS provider does this.
      IPAddr.new(Resolv.getaddress(address))
    end

    ip
  end

  # Generate a list of hostnames for a vagrant machine
  #
  # This function resolves a list of hostnames or special keys into a list of
  # hostnmaes.
  #
  # Special keys currently supported:
  #
  #   - `@vagrant_hostnames`: See {#hostnames_for_machine}.
  #
  # @param aliases [Array<String>] A list of hostnames or special keys.
  # @param machine [Vagrant::Machine] The Vagrant machine to use when resolving
  #   aliases.
  #
  # @return [Array<String>] A list of hostnames.
  def resolve_aliases(aliases, machine)
    aliases.flat_map do |a|
      case a
      when '@vagrant_hostnames'
        hostnames_for_machine(machine)
      else
        a
      end
    end
  end

  # @return [Array<Vagrant::Machine>]
  def all_machines(env)
    env.active_machines.map do |vm_id|
      begin
        env.machine(*vm_id)
      rescue Vagrant::Errors::MachineNotFound
        nil
      end
    end.compact
  end

end
