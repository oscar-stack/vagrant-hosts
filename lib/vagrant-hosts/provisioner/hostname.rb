require 'vagrant'

# Abstract the details of setting a guest hostname on different versions of
# Vagrant.
#
# Vagrant commit 61d2f9f96fc0f0ef5869c732674f25c4ccc85c8c converts the
# #change_host_name # method to a capability, which breaks the API between
# 1.1 and 1.2. :(
module VagrantHosts::Provisioner::Hostname

  # @param name [String] The new hostname to apply on the guest
  def change_host_name(name)
    case Vagrant::VERSION
    when /1\.1/
      @machine.guest.change_host_name(name)
    when /1\.2/
      @machine.guest.capability(:change_host_name, name)
    else
      raise RuntimeError, "#{Vagrant::VERSION} isn't a recognized Vagrant version, can't reliably shim `change_host_name`"
    end
  end
end
