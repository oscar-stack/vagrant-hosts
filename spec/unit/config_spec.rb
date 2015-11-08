require 'spec_helper'

require 'vagrant-hosts/config'

describe VagrantHosts::Config do
  let(:machine)  { double('machine') }

  describe 'hosts' do
    it 'requires aliases to be an array' do
      subject.add_host '127.0.0.1', 'local.server'
      subject.finalize!

      errors = subject.validate(machine)

      expect(errors['Vagrant Hosts'].to_s).to match(/should have an array of aliases/)
    end

    it 'accepts an array of aliases' do
      subject.add_host '127.0.0.1', ['local.server']
      subject.finalize!

      errors = subject.validate(machine)

      expect(errors['Vagrant Hosts']).to eq []
    end

    it 'can be merged' do
      subject.add_host '127.0.0.1', ['local.server']
      subject.finalize!

      other = described_class.new
      other.add_host '10.0.20.1', ['other.server']
      other.finalize!

      result = subject.merge(other)

      expect(result.hosts).to eq [
        ["127.0.0.1", ["local.server"]],
        ["10.0.20.1", ["other.server"]]]
    end

  end
end
