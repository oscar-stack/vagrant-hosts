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

  [:darwin, :freebsd, :linux, :solaris, :solaris11].each do |os|
    guest_capability(os, 'sync_hosts') do
      require_relative 'cap'
      VagrantHosts::Cap::SyncHosts::POSIX
    end
  end

  guest_capability(:windows, 'sync_hosts') do
    require_relative 'cap'
    VagrantHosts::Cap::SyncHosts::Windows
  end


  [:darwin, :freebsd, :linux, :solaris, :solaris11].each do |os|
    guest_capability(os, 'network_facts') do
      require_relative 'cap'
      VagrantHosts::Cap::Facts::POSIX
    end
  end

  guest_capability(:windows, 'network_facts') do
    require_relative 'cap'
    VagrantHosts::Cap::Facts::Windows
  end

  command(:hosts) do
    require_relative 'command'
    VagrantHosts::Command
  end

  # Internal action hooks
  action_hook('Vagrant Hosts: vagrant version check', :environment_load) do |hook|
    require 'vagrant-hosts/action/version_check'
    hook.prepend VagrantHosts::Action::VersionCheck
  end

  # ConfigBuilder tie-ins

  def self.config_builder_hook
    require_relative 'config_builder'
  end
end
