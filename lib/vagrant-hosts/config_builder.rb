require 'config_builder/model'

module VagrantHosts
  module ConfigBuilder
    class Model < ::ConfigBuilder::Model::Base

      # @!attribute [rw] hosts
      attr_accessor :hosts
      # @!attribute [rw] autoconfigure
      attr_accessor :autoconfigure

      def initialize
        @hosts = []
      end

      def to_proc
        Proc.new do |vm_config|
          vm_config.provision :hosts do |h_config|
            h_config.autoconfigure = @autoconfigure if defined? @autoconfigure

            @hosts.each do |(address, aliases)|
              h_config.add_host address, aliases
            end
          end
        end
      end

      ::ConfigBuilder::ModelCollection.provisioner.register('hosts', self)
    end
  end
end
