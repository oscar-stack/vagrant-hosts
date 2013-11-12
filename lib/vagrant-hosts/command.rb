require 'vagrant'
module VagrantHosts
  class Command < Vagrant.plugin('2', :command)

    require 'vagrant-hosts/command/helpers'
    include VagrantHosts::Command::Helpers
    
    require 'vagrant-hosts/addresses'


    require 'vagrant-hosts/command/puppetize'
    require 'vagrant-hosts/command/list'

    def initialize(argv, env)
      @argv     = argv
      @env      = env
      @cmd_name = 'hosts'

      split_argv
      register_subcommands

    end

    def execute
      invoke_subcommand
    end

    private

    def register_subcommands
      @subcommands = Vagrant::Registry.new

      @subcommands.register('puppetize') do
        VagrantHosts::Command::Puppetize
      end

      @subcommands.register('list') do
        VagrantHosts::Command::List
      end
    end
  end
end
