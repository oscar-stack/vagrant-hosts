require 'vagrant'
require 'vagrant-hosts'
require 'vagrant-hosts/version'

if Vagrant::VERSION < VagrantHosts::REQUIRED_VAGRANT_VERSION
  raise "vagrant-hosts version #{VagrantHosts::VERSION} requires Vagrant " +
    "#{VagrantHosts::REQUIRED_VAGRANT_VERSION} or later"
end

class VagrantHosts::Plugin < Vagrant.plugin(2)
  name 'hosts'

  description <<-DESC
  This plugin adds commands and provisioners to manage static host entries on
  Vagrant guests.
  DESC

  provisioner(:hosts) do
    require_relative 'provisioner'
    VagrantHosts::Provisioner
  end

  config(:hosts, :provisioner) do
    require_relative 'config'
    VagrantHosts::Config
  end

  action_hook(:hosts, :config_builder_extension) do
    require_relative 'config_builder'
  end
end
