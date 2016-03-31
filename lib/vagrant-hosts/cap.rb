module VagrantHosts
  module Cap
    module SyncHosts
      require 'vagrant-hosts/cap/sync_hosts/base'
      require 'vagrant-hosts/cap/sync_hosts/posix'
      require 'vagrant-hosts/cap/sync_hosts/windows'
    end
  end
end
