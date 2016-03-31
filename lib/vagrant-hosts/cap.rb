module VagrantHosts
  module Cap
    module SyncHosts
      require 'vagrant-hosts/cap/sync_hosts/base'
      require 'vagrant-hosts/cap/sync_hosts/posix'
      require 'vagrant-hosts/cap/sync_hosts/windows'
    end

    module Facts
      require_relative 'cap/facts/posix'
      require_relative 'cap/facts/windows'
    end
  end
end
