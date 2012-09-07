require 'vagrant-hosts/provisioners/hosts'


Vagrant.provisioners.register(:hosts) { VagrantHosts::Provisioner }
