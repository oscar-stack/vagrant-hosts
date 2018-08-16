require_relative 'base'

# Base class for retrieving network facts from POSIX
#
# @since 2.8.0
class VagrantHosts::Cap::Facts::POSIX < VagrantHosts::Cap::Facts::Base

  def load_facts
    facts = {}
    facts['networking'] = {}
    facts['networking']['interfaces'] = parse_ifconfig

    iface = get_default_iface
    facts['networking']['ip'] = facts['networking']['interfaces'][iface]['ip']

    facts
  end

  private

  def ifconfig
    ifconfig_output = sudo('ifconfig -a')[:stdout]
    # Group output by interface.
    ifconfig_output.split(/^([[:alnum:]]+[:]?\s)/).drop(1).each_slice(2).map(&:join)
  end

  def parse_ifconfig
    results = ifconfig.map do |i|
      i.match(/^([[:alnum:]]+)[:]?\s.*inet (?:addr:)?([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/m)
    end.compact.map do |r|
      name, ip = r.captures
      [name, {'ip' => ip}]
    end

    Hash[results]
  end

  def get_default_iface
    route_table = sudo('netstat -rn')[:stdout]
    default = route_table.lines.find {|e| e.start_with?('default') || e.start_with?('0.0.0.0')}

    default.split.last.chomp
  end

  private

  def sudo(cmd)
    stdout = ''
    stderr = ''

    # FIXME: The chomp operations below smell like cargo culting. I have no
    #        idea why we do it and it breaks on WinRM 2.x which uses PSRP
    #        instead of routing though the CMD shell.
    retval = machine.communicate.sudo(cmd) do |type, data|
      if type == :stderr
        stderr << data.chomp
      else
        stdout << data.chomp
      end
    end

    {:stdout => stdout, :stderr => stderr, :retval => retval}
  end
end
