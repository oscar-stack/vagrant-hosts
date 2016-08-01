require 'spec_helper'

require 'vagrant-hosts/addresses'

describe 'VagrantHosts::Addresses' do
  subject do
    # A simple class which simulates inclusion of VagrantHosts::Addresses
    Class.new do
      include VagrantHosts::Addresses
      # Expose private methods included above for testing.
      public *self.private_instance_methods
    end.new
  end

  describe '#resolve_ip' do
    it 'raises an error when passed an unresolvable hostname' do
      expect{ subject.resolve_ip('somewhere.bogusdomain') }.to \
        raise_error(VagrantHosts::Addresses::UnresolvableHostname, /somewhere.bogusdomain/)
    end
  end
end
