require 'vagrant'

module VagrantHosts
  module Provisioner
    class Hosts < Vagrant.plugin('2', :provisioner)

      def initialize(machine, config)
        super
      end

      def provision
        @machine.guest.capability(:sync_hosts, @config)
      end

    end
  end
end
