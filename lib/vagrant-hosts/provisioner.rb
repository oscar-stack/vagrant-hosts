require 'vagrant'
require 'tempfile'

module VagrantHosts
  class Provisioner < Vagrant.plugin('2', :provisioner)

    require 'vagrant-hosts/provisioner/hostname'
    require 'vagrant-hosts/provisioner/linux'

    def initialize(machine, config)
      @machine, @config = machine, config
    end

    # @todo use guest capabilities instead of hardcoded provisioner provider
    def provision
      driver = Linux.new(@machine, @config)
      driver.sync!
    end
  end
end
