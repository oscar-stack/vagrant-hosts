class VagrantHosts::Command::List < Vagrant.plugin('2', :command)

  include VagrantHosts::Command::Helpers
  include VagrantHosts::Addresses

  def initialize(argv, env)
    @argv     = argv
    @env      = env
    @cmd_name = 'hosts list'

    split_argv
  end

  def execute
    
    argv = parse_options(parser)

    @env.ui.info format_hosts
    0
  end

  private

  def format_hosts
    vagrant_hosts(@env).inject('') do |str, (address, aliases)|
      str << "#{address} #{aliases.join(' ')}\n"
    end
  end


  def parser
    OptionParser.new do |o|
      o.banner = "Usage: vagrant #{@cmd_name} [<args>]"
      o.separator ''

      o.on('-h', '--help', 'Display this help message') do
        puts o
        exit 0
      end
    end
  end
end
