require 'ipaddr'
require 'socket' # For Addrinfo

require 'vagrant/errors'

module VagrantHosts::Addresses

  # Cache for networking data
  #
  # @return [Hash{String => Hash{String => String}}]
  # @private
  #
  # @since 2.7.0
  CACHE ||= {}

  class UnresolvableHostname < ::Vagrant::Errors::VagrantError
    error_key(:unresolvable_hostname, 'vagrant_hosts.errors')
  end

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

    all_hosts += resolve_host_entries(config.hosts, @machine)

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
  #
  # @since 2.7.0
  def collect_imports(machine, config)
    env = machine.env
    imports = config.imports

    # TODO: Use Set?
    hosts = []

    all_machines(env).each do |m|
      next if m.name == machine.name

      host_provisioners(m).each do |p|
        imports.each do |k|
          next unless p.config.exports.has_key?(k)
          begin
            hosts.concat resolve_host_entries(p.config.exports[k], m)
          rescue Vagrant::Errors::VagrantError => e
            machine.ui.error I18n.t(
              'vagrant_hosts.errors.collection_failed',
              :host   => m.name.to_s,
              :error_class => e.class,
              :message => e.message
            )
          end
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
  #
  # @since 2.7.0
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
  #
  # @since 2.7.0
  def resolve_addresses(address, machine)
    # Some network addresses, such as ssh_info, can be expensive to
    # look up from cloud environments such as AWS, vSphere and OpenStack.
    # So, we cache these special keys.
    if CACHE.key?(machine.name) && CACHE[machine.name].key?(address)
      ips = CACHE[machine.name][address]
    else
      ips = case address
      when '@vagrant_private_networks'
        machine.config.vm.networks.map do |(net_type, opts)|
          next unless net_type == :private_network
          opts[:ip]
        end.compact
      when '@vagrant_ssh'
        if (info = machine.ssh_info)
          info[:host]
        else
          []
        end
      when '@facter_ipaddress'
        machine.guest.capability(:network_facts)['networking']['ip']
      else
        address
      end

      if address.start_with?('@')
        CACHE[machine.name] ||= {}
        CACHE[machine.name][address] = ips
      end
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
  # @raise [VagrantHosts::Addresses::UnresolvableHostname] If `address` is a
  #   maformed IP address or unresolvable hostname.
  #
  # @return [IPAddr] An IP address.
  #
  # @since 2.7.0
  def resolve_ip(address)
    ip = begin
      IPAddr.new(address)
    rescue IPAddr::InvalidAddressError
      nil
    end

    ip ||= begin
      # Wasn't an IP address. Resolve it. The "@vagrant_ssh" returns a
      # hostname instead of IP when the AWS provider is in use.
      #
      # NOTE: Name resolution is done using Ruby's Addrinfo instead of Resolv
      # as Addrinfo always uses the system resolver library and thus picks up
      # platform-specific behavior such as the OS X /etc/resolver/ directory.
      IPAddr.new(Addrinfo.ip(address).ip_address)
    rescue IPAddr::InvalidAddressError, SocketError
      nil
    end

    if ip.nil?
      raise UnresolvableHostname, address: address
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
  #
  # @since 2.7.0
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

  # NOTE: This method exists for compatibility with Vagrant 1.6 and earlier.
  # Remove it once support for these versions is dropped.
  def host_provisioners(machine)
    machine.config.vm.provisioners.select do |p|
      if Vagrant::VERSION < '1.7'
        p.name.intern == :hosts
      else
        p.type.intern == :hosts
      end
    end
  end
end
