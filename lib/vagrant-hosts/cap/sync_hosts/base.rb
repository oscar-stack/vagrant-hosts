require 'vagrant-hosts/addresses'

# Abstract guest capability for syncing host resources
#
# @abstract
# @since 2.0.0
class VagrantHosts::Cap::SyncHosts::Base
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

    update_hosts
  end

  private

  # Upload /etc/hosts content to a temporary file on the guest
  def upload_temphosts(hosts_content, dest_path = '/tmp/vagrant-hosts.txt')
    temp_file = nil

    temp_file = Tempfile.new('vagrant-hosts')
    temp_file.binmode # Don't convert line endings.

    temp_file.write(hosts_content)
    temp_file.flush
    @machine.communicate.upload(temp_file.path, dest_path)
  ensure
    temp_file.close unless temp_file.nil?
  end

  # Update the hosts file on a machine
  #
  # Subclasses should implement this method with OS-specific logic.
  def update_hosts
    raise NotImplementedError
  end

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
