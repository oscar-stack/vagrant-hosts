require_relative 'base'

# Base class for retrieving network facts from Windows
#
# @since 2.8.0
class VagrantHosts::Cap::Facts::Windows < VagrantHosts::Cap::Facts::Base

  def load_facts
    facts = {}
    facts['networking'] = {}
    facts['networking']['interfaces'] = parse_ifconfig

    iface = get_default_iface
    facts['networking']['ip'] = iface

    facts
  end

  private

  def parse_ifconfig
    # Imagine a call to Get-WmiObject -Query that returns a combined dataset
    # built from Win32_NetworkAdapter (interface names) and
    # Win32_NetworkAdapterConfiguration (everything else, like ipaddress).
    #
    # TODO: Implement said query.

    Hash.new
  end

  def get_default_iface
    route_table = sudo('netstat -rn')[:stdout]

    default = route_table.lines.find do |e|
      e.lstrip.start_with?('default') ||
      e.lstrip.start_with?('0.0.0.0')
    end

    default.split[-2].chomp
  end

  private

  # FIXME: de-duplicate with posix implementation after figuring out what
  #        happens to newlines.
  def sudo(cmd)
    stdout = ''
    stderr = ''

    retval = machine.communicate.sudo(cmd) do |type, data|
      if type == :stderr
        stderr << data
      else
        stdout << data
      end
    end

    {:stdout => stdout, :stderr => stderr, :retval => retval}
  end
end
