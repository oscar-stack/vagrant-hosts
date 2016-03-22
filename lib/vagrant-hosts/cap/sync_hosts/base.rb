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
    # call to method not implemented by abstract base class
    update_hosts
  end
end
