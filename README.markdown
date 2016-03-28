vagrant-hosts
=============

Manage vagrant guest local DNS resolution.

[![Build Status](https://travis-ci.org/oscar-stack/vagrant-hosts.svg?branch=master)](https://travis-ci.org/oscar-stack/vagrant-hosts)

Synopsis
========

The `vagrant-hosts` plugin provides a `hosts` provisioner which assembles hosts file content based on explicit information and `private_network` settings. Dynamic sources of hostname info, such as DHCP or provider-specific SSH info are currently not considered.


Provisioner Settings
--------------------

These settings are on a per provisioner basis. They configure the individual
behaviors of each provisioner instance.

  * `hosts`
    * Description: An array of tuples containing:
      - An IP address
      - A list of hostnames match with that address.
      These entries may use special eys as described in the next section.
    * Default: `[]`
  * `exports`
    * Description: A hash containing named lists of `[address, [aliases]]`
      entries that are exported by this VM. These exports can be collected
      by other VMs using the imports setting. These entries may use special
      keys as described in the next section.
    * Default: `{}`
  * `imports`
    * Description: A list of named exports to collect from other VMs.
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

### Special Keys

The tuples used by the `hosts` and `exports` settings are of the form:

    [address, [aliases]]

For each component, there are some special keys defined that will be replaced by
data determined from the VM.

For `address`, the following special keys may be used:

  - `@vagrant_private_networks`: Expands to create one host entry with the given
    `aliases` for each private network attached to a VM that has an explicitly
    configured `ip` address. This is similar to the `autoconfigure` setting, but
    gives control over which aliases are used.

  - `@vagrant_ssh`: Expands to the IP address that `vagrant ssh` uses to connect
    with the VM.

For `aliases`, the following special keys may be used:

  - `@vagrant_hostnames`: Expands to an array of aliases containing:
        <vm hostname> <first component of vm hostname> <vm name>


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

- - -

Use exports and special keys to share names among VMs:

```ruby
Vagrant.configure('2') do |config|

  # A node running in a remote compute environment, such as AWS or OpenStack.
  config.vm.define :cloud do |node|
    node.vm.provision :hosts do |provisioner|
      provisioner.sync_hosts = true
      provisioner.exports = {
        'global' => [
          ['@vagrant_ssh', ['@vagrant_hostnames']],
        ],
      }
    end
  end

  # A node running locally under Virtualbox
  config.vm.define :local do |node|
    node.vm.provision :hosts do |provisioner|
      provisioner.sync_hosts = true
      provisioner.imports = ['global', 'virtualbox']
      provisioner.exports = {
        'virtualbox' => [
          ['@vagrant_private_networks', ['@vagrant_hostnames']],
        ],
      }
    end
  end
end
```

Vagrant Commands
----------------

The `vagrant-hosts` plugin provides two Vagrant commands:

  - `vagrant hosts list`: List private_network host info in /etc/hosts format
  - `vagrant hosts puppetize`: List private_network host info as Puppet Host resources

Supported Platforms
-------------------

As of version 1.0.0 or later Vagrant 1.1 is required.

Supported guests:

  * POSIX
  * Windows

Installation
------------

    vagrant plugin install vagrant-hosts
