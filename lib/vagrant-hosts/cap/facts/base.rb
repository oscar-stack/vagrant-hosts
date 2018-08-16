# Base class for retrieving network facts from guest VMs
#
# @since 2.8.0
class VagrantHosts::Cap::Facts::Base

  # Retrieve facts from a guest VM
  #
  # See {#load_facts} for implementation details.
  #
  # @return [Hash] A hash of facts.
  def self.network_facts(machine)
    new(machine).load_facts
  end

  attr_reader :machine

  def initialize(machine)
    @machine = machine
  end

  def load_facts
    raise NotImplementedError
  end
end
