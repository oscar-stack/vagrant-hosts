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
    # This ensures that a default hostname is created from the macine name
    # if the VM wasn't configured with a hostname.
    #
    # FIXME: Write tests for this behavior.
    # TODO: Move this behavior into a config block on the hosts provisioner
    # so that this capability can remain focused on updating /etc/hosts.
    if @config.change_hostname
      hostname = @machine.config.vm.hostname || @machine.name.to_s
      change_host_name(hostname)
    end

    # call to method not implemented by abstract base class
    update_hosts
  end

  private

  # @param name [String] The new hostname to apply on the guest
  def change_host_name(name)
    case Vagrant::VERSION
    when /^1\.1/
      @machine.guest.change_host_name(name)
    else
      @machine.guest.capability(:change_host_name, name)
    end
  end

end
