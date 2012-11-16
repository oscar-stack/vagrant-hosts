vagrant-hosts
=============

Manage vagrant guest local DNS resolution.

Synopsis
--------

    Vagrant::Config.run do |config|
      config.vm.box = "ubuntu-12.04-server-i386"

      config.vm.provision :hosts do |provisioner|
        # Add a single hostname
        provisioner.add_host '10.0.2.2', ['myhost.vagrantup.internal']
        # Or a fqdn and a short hostname
        provisioner.add_host '10.0.2.3', ['myotherhost.vagrantup.internal', 'myotherhost'] 
        # Or as many aliases as you like!
        provisioner.add_host '10.0.2.5', [
          'mypuppetmaster.vagrantup.internal',
          'puppet.vagrantup.internal',
          'mypuppetmaster',
          'puppet'
        ]
      end
    end

Supported Guest Platforms
-------------------------

  * Linux
  * (soon) Windows (As soon as I get a chance to incorporate the driver)

Installation
------------

    # For full releases
    gem install vagrant-hosts
    # For pre releases
    gem install --pre vagrant-hosts
    # Vagrant hosts magic!
