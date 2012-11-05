# Declare top level vagrant hosts module.
module VagrantHosts; end

require 'vagrant-hosts/version'
require 'vagrant-hosts/provisioners/hosts'

Vagrant.provisioners.register(:hosts) { VagrantHosts::Provisioner }
