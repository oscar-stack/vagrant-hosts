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

    context 'when merging' do
      let(:other) { described_class.new }

      it 'combines hosts arrays' do
        subject.add_host '127.0.0.1', ['local.server']
        subject.finalize!

        other.add_host '127.0.0.1', ['some-alias']
        other.add_host '10.0.20.1', ['other.server']
        other.finalize!

        result = subject.merge(other)

        expect(result.hosts).to eq [['127.0.0.1', ['local.server']],
                                    ['127.0.0.1', ['some-alias']],
                                    ['10.0.20.1', ['other.server']]]
      end

      it 'combines import arrays' do
        subject.imports = ['foo', 'baz']
        subject.finalize!

        other.imports = ['foo', 'bar']
        other.finalize!

        result = subject.merge(other)

        expect(result.imports).to eq ['foo', 'baz', 'bar']
      end

      it 'merges export hashes' do
        subject.exports = {global: [["127.0.0.1", ["local.server"]]]}
        subject.finalize!

        other.exports = {global: [["127.0.0.1", ["test.server"]]],
                         some_provider: [["127.0.0.1", ["some-alias"]]]}
        other.finalize!

        result = subject.merge(other)

        expect(result.exports).to eq({global: [['127.0.0.1', ['local.server']],
                                               ['127.0.0.1', ['test.server']]],
                                      some_provider: [["127.0.0.1", ["some-alias"]]]})
      end
    end
  end
end
