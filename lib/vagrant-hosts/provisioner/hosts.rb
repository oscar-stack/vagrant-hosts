require 'vagrant'
require 'vagrant-hosts/addresses'

module VagrantHosts
  module Provisioner
    class Hosts < Vagrant.plugin('2', :provisioner)
      include VagrantHosts::Addresses

      def provision
        @machine.guest.capability(:sync_hosts, @config)
        sync_hosts! if @config.sync_hosts
      end

      def cleanup
        sync_hosts! if @config.sync_hosts
      end

      private

      # Update hosts on other VMs.
      def sync_hosts!
        env = @machine.env

        # Gathers every _other_ machine in the vagrant environment which is
        # running and has a hosts provider.
        machines_to_provision = all_machines(env).select do |vm|
          calling_machine = (vm.name.to_s == machine.name.to_s)
          running = begin
            vm.communicate.ready?
          rescue Vagrant::Errors::VagrantError
            # WinRM will raise an error if the VM isn't running instead of
            # returning false (mitchellh/vagrant#6356).
            false
          end
          has_hosts = if Vagrant::VERSION < '1.7'
            vm.config.vm.provisioners.any? {|p| p.name.intern == :hosts}
          else
            vm.config.vm.provisioners.any? {|p| p.type.intern == :hosts}
          end

          running && has_hosts && (not calling_machine)
        end

        machines_to_provision.each do |vm|
          vm.ui.info "Updating hosts on: #{vm.name}"
          host_provisioners(vm).each do |p|
            # Duplicate the hosts configuration.
            hosts_config = @config.class.new.merge(p.config)
            # Set sync_hosts to false to avoid recursion.
            hosts_config.sync_hosts = false
            hosts_config.finalize!

            self.class.new(vm, hosts_config).provision
          end
        end
      end

    end
  end
end
