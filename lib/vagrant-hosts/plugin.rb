require 'vagrant'
require 'vagrant-hosts'
require 'vagrant-hosts/version'

class VagrantHosts::Plugin < Vagrant.plugin(2)
  name 'hosts'

  description <<-DESC
  This plugin adds commands and provisioners to manage static host entries on
  Vagrant guests.
  DESC

  config(:hosts, :provisioner) do
    require_relative 'config'
    VagrantHosts::Config
  end

  provisioner(:hosts) do
    require_relative 'provisioner/hosts'
    VagrantHosts::Provisioner::Hosts
  end

  # Guest capabilities for vagrant-hosts

  guest_capability(:linux, 'sync_hosts') do
    require_relative 'cap'
    VagrantHosts::Cap::SyncHosts::POSIX
  end

  guest_capability(:solaris, 'sync_hosts') do
    require_relative 'cap'
    VagrantHosts::Cap::SyncHosts::POSIX
  end

  guest_capability(:windows, 'sync_hosts') do
    require_relative 'cap'
    VagrantHosts::Cap::SyncHosts::Windows
  end

  command(:hosts) do
    require_relative 'command'
    VagrantHosts::Command
  end

  # ConfigBuilder tie-ins

  def self.config_builder_hook
    require_relative 'config_builder'
  end
end
