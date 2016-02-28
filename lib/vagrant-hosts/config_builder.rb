require 'config_builder/version'

if ConfigBuilder::VERSION > '1.0'
  require_relative 'config_builder/1_x.rb'
else
  require_relative 'config_builder/0_x.rb'
end
