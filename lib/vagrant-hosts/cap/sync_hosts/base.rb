# Provide an abstract base class for syncing hosts entries
class VagrantHosts::Cap::SyncHosts::Base

  require 'vagrant-hosts/addresses'
  include VagrantHosts::Addresses

  def self.sync_hosts(machine, config)
    new(machine, config).sync!
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
    when /^1\.[234]/
      @machine.guest.capability(:change_host_name, name)
    else
      raise UnknownVersion, :vagrant_version => Vagrant::VERSION
    end
  end

end
