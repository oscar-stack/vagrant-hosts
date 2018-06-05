require 'config_builder/model'

# Integration with ConfigBuilder 1.x and newer
#
# @since 2.7.0
module VagrantHosts
  module ConfigBuilder
    class Model < ::ConfigBuilder::Model::Provisioner::Base

      # @!attribute [rw] hosts
      def_model_attribute :hosts
      # @!attribute [rw] autoconfigure
      def_model_attribute :autoconfigure
      # @!attribute [rw] add_localhost_hostnames
      def_model_attribute :add_localhost_hostnames
      # @!attribute [rw] sync_hosts
      def_model_attribute :sync_hosts
      # @!attribute [rw] exports
      def_model_attribute :exports
      # @!attribute [rw] exports
      def_model_attribute :imports

      # @private
      def configure_exports(config, val)
        val.each do |k, v|
          config.exports[k] ||= []
          config.exports[k] += v
        end

        config.exports.each do |k, v|
          new_value = {}
          v.each do |ip, hostnames|
            if new_value.has_key?(ip)
              new_value[ip] += hostnames
            else
              new_value[ip] = hostnames.dup
            end
          end

          new_value.each {|_, v| v.uniq!}
          config.exports[k] = new_value
        end
      end

      # @private
      def configure_imports(config, val)
        config.imports += val
        config.imports.uniq!
      end

      # @private
      def configure_hosts(config, val)
        val.each do |(address, aliases)|
          config.add_host(address, aliases)
        end
      end

      ::ConfigBuilder::Model::Provisioner.register('hosts', self)
    end
  end
end
