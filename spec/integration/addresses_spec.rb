require 'spec_helper'

require 'vagrant-hosts/addresses'
require 'vagrant-hosts/config'


describe 'Vagrant Integration: VagrantHosts::Addresses' do
  include_context 'vagrant-unit'

  let(:test_env)    {
    env = isolated_environment

    env.vagrantfile <<-EOF
Vagrant.configure('2') do |config|
  config.vm.define 'machine-a' do |node|
    node.vm.hostname = 'machine-a.testvm'

    node.vm.network :private_network, ip: '10.40.1.1'
    node.vm.network :private_network, ip: '10.40.1.3'

    node.vm.provision 'hosts' do |p|
      p.exports = {
        'global' => [
          ['@vagrant_private_networks', ['@vagrant_hostnames']]
        ],
      }
    end
  end

  config.vm.define 'machine-b' do |node|
    node.vm.network :private_network, ip: '10.40.1.2'

    node.vm.provision 'hosts' do |p|
      p.exports = {
        'global' => [
          ['@vagrant_private_networks', ['@vagrant_hostnames']],
        ],
        'ssh' => [
          ['@vagrant_ssh', ['@vagrant_hostnames']],
        ],
      }
    end
  end
end
EOF
    env
  }
  let(:env)         {
    test_env.create_vagrant_env(local_data_path: "#{test_env.workdir}/.vagrant")
  }
  let(:machine_a)     { env.machine(:'machine-a', :dummy) }
  let(:machine_b)     { env.machine(:'machine-b', :dummy) }

  subject do
    # A simple class which simulates inclusion of VagrantHosts::Addresses
    Class.new do
      include VagrantHosts::Addresses
      # Expose private methods included above for testing.
      public *self.private_instance_methods

      def initialize(env, machine)
        # Create instance variables that VagrantHosts::Addresses expects to
        # have access to.
        @env = env
        @machine = machine
      end
    end.new(env, machine_a)
  end

  # Mark test VMs as active.
  before :each do
    allow(env).to receive(:active_machines).and_return([
      [:'machine-a', :dummy],
      [:'machine-b', :dummy],
    ])

    # Give Machine B a SSH address.
    allow(machine_b).to receive(:ssh_info).and_return({:host => '10.40.1.4'})
  end

  describe '#vagrant_hosts' do
    it 'returns private_network entries for each machine' do
      expect(subject.vagrant_hosts(env)).to include(
        ['10.40.1.1', ['machine-a.testvm', 'machine-a']],
        ['10.40.1.3', ['machine-a.testvm', 'machine-a']],
        ['10.40.1.2', ['machine-b']],
      )
    end
  end

  describe '#collect_imports' do
    it 'returns imports from other machines' do
      config = VagrantHosts::Config.new
      config.imports = ['global', 'ssh']
      config.finalize!

      expect(subject.collect_imports(machine_a, config)).to eq([
        [IPAddr.new('10.40.1.2'), ['machine-b']],
        [IPAddr.new('10.40.1.4'), ['machine-b']],
      ])
    end
  end

  describe '#all_hosts' do
    it 'resolves special addresses and aliases' do
      config = VagrantHosts::Config.new
      config.add_host '@vagrant_private_networks', ['@vagrant_hostnames']
      config.finalize!

      expect(subject.all_hosts(config)).to include(
        [IPAddr.new('10.40.1.1'), ['machine-a.testvm', 'machine-a']],
      )
    end
  end
end
