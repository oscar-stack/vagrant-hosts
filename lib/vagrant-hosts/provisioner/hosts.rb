require 'vagrant'

module VagrantHosts
  module Provisioner
    class Hosts < Vagrant.plugin('2', :provisioner)

      def initialize(machine, config)
        super
      end

      def provision
        driver = @machine.guest.capability(:sync_hosts, @config)
        driver.sync!
      end

    end
  end
end
