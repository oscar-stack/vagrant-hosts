module VagrantHosts::Command::Helpers

  private

  def split_argv
    @main_args, @subcommand, @sub_args = split_main_and_subcommand(@argv)
  end

  def invoke_subcommand
    if @subcommand and (klass = @subcommands.get(@subcommand))
      klass.new(@argv, @env).execute
    elsif @subcommand
      @env.ui.error "Unrecognized subcommand: #{@subcommand}"
      print_subcommand_help(:error)
    else
      print_subcommand_help
    end
  end

  def print_subcommand_help(output = :info)
    msg = []
    msg << "Usage: vagrant #{@cmd_name} <command> [<args>]"
    msg << ''
    msg << 'Available subcommands:'

    keys = []
    @subcommands.each { |(key, _)| keys << key }
    msg += keys.sort.map { |key| "     #{key}" }

    msg << ''
    msg << "For help on any individual command run `vagrant #{@cmd_name} <command> -h`"

    @env.ui.send(output, msg.join("\n"))
  end
end
