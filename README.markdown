vagrant-hosts
=============

Manage vagrant guest local DNS resolution.

[![Build Status](https://travis-ci.org/oscar-stack/vagrant-hosts.svg?branch=master)](https://travis-ci.org/oscar-stack/vagrant-hosts)

Synopsis
========

Provisioner Settings
--------------------

These settings are on a per provisioner basis. They configure the individual
behaviors of each provisioner instance.

  * `hosts`
    * Description: An array of tuples containing:
      - An IP address
      - A list of hostnames match with that address.
    * Default: `[]`
  * `autoconfigure`
    * Description: A boolean which controls whether hosts are pulled in from other machines.
    * Default: `true` if hosts is empty, otherwise `false`.
  * `add_localhost_hostnames`
    * Description: A boolean which controls whether the hostname of the machine is added as an alias for `127.0.1.1`
    * Default: `true`
  * `sync_hosts`
    * Description: A boolean which controls whether running the hosts provisioner causes an update on all other running machines.
      This also happens during machine destruction.
    * Default: `false`


Example Usage
-------------

Manually specify addresses:

```ruby
Vagrant.configure('2') do |config|
  config.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"

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
```

- - -

Autodetect internal network addresses and autoconfigure hosts:

```ruby
# Autoconfigure hosts. This will copy the private network addresses from
# each VM and update hosts entries on all other machines. No further
# configuration is needed.
Vagrant.configure('2') do |config|

  config.vm.define :first do |node|
    node.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"
    node.vm.network :private_network, :ip => '10.20.1.2'
    node.vm.provision :hosts, :sync_hosts => true
  end

  config.vm.define :second do |node|
    node.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"
    node.vm.network :private_network, :ip => '10.20.1.3'
    node.vm.provision :hosts, :sync_hosts => true
  end
end
```

- - -

Use autodetection with manual entries

```ruby
Vagrant.configure('2') do |config|

  config.vm.define :first do |node|
    node.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"
    node.vm.network :private_network, :ip => '10.20.1.2'
    node.vm.provision :hosts do |provisioner|
      provisioner.autoconfigure = true
      provisioner.sync_hosts = true
      provisioner.add_host '172.16.3.10', ['yum.mirror.local']
    end

  end

  config.vm.define :second do |node|
    node.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"
    node.vm.network :private_network, :ip => '10.20.1.3'
    node.vm.provision :hosts do |provisioner|
      provisioner.autoconfigure = true
      provisioner.sync_hosts = true
      provisioner.add_host '172.16.3.11', ['apt.mirror.local']
    end
  end
end
```

Supported Platforms
-------------------

As of version 1.0.0 or later Vagrant 1.1 is required.

Supported guests:

  * POSIX
  * Windows

Installation
------------

    vagrant plugin install vagrant-hosts
