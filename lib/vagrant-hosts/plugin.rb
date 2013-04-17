require 'vagrant'
require 'vagrant-hosts'
require 'vagrant-hosts/version'

if Vagrant::VERSION < "1.2.0"
  raise "vagrant-hosts version #{VagrantHosts::VERSION} requires Vagrant 1.2 or later"
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
end
