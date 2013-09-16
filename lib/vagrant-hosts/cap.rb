module VagrantHosts
  module Cap
    module SyncHosts

      class SyncHostsFailed < Vagrant::Errors::VagrantError
        error_key(:sync_hosts_failed, 'vagrant_hosts.cap.sync_hosts')
      end

      class UnknownVersion < Vagrant::Errors::VagrantError
        error_key(:unknown_version, 'vagrant_hosts.cap.sync_hosts')
      end

      require 'vagrant-hosts/cap/sync_hosts/base'
      require 'vagrant-hosts/cap/sync_hosts/posix'
      require 'vagrant-hosts/cap/sync_hosts/windows'

    end
  end
end
