# Guest capability for updating System32/drivers/etc/hosts on Windows
#
# @see https://docs.microsoft.com/en-us/previous-versions//bb727005(v=technet.10)#EDAA
#   Microsoft docs on hostname resolution.
# @since 2.0.0
class VagrantHosts::Cap::SyncHosts::Windows < VagrantHosts::Cap::SyncHosts::Base

  private

  def update_hosts
    hosts_content = format_hosts
    temp_file = [get_tempdir, 'vagrant-hosts.txt'].join('/')
    upload_temphosts(hosts_content, temp_file)

    @machine.communicate.sudo(<<-EOS)
Copy-Item `
  -Path "#{temp_file}" `
  -Destination "${Env:WINDIR}/System32/drivers/etc/hosts"
EOS
  end

  # Return the path of the Windows temporary directory
  def get_tempdir
    sudo('Write-Host -Object $Env:TEMP')[:stdout].chomp.gsub("\\", '/')
  end

  def format_hosts
    all_hosts(@config).inject('') do |str, (address, aliases)|
      # Unlike UNIXy systems, Windows limits the number of host aliases
      # that can appear on a line to 9.
      aliases.each_slice(9) do |slice|
        str << "#{address} #{slice.join(' ')}\r\n"
      end

      str
    end
  end

  # Windows needs a modification of the base method because Windows guest names
  # cannot be fully-qualified domain names (they cannot contain the "."
  # character). Therefore, modify the input name to convert illegal characters
  # to legal replacements.
  #
  # @param name [String] The new hostname to apply on the guest
  def change_host_name(name)

    # First set the machine name (hostname)
    components = name.split('.')
    hostname   = components.first
    domainname = components.slice(1, components.size).join('.')

    super(hostname)

    # Next set the Primary DNS Suffix, if it makes sense (domainname)
    unless domainname.empty?
      change_domain_name(domainname)
    end
  end

  def change_domain_name(domainname)
    # Source: http://poshcode.org/2958
    # Note that whitespace is important in this inline powershell script due
    # to the use of a here-string.
    powershell = <<-END_OF_POWERSHELL
function Set-PrimaryDnsSuffix {
  param ([string] $Suffix)

  # http://msdn.microsoft.com/en-us/library/ms724224(v=vs.85).aspx
  $ComputerNamePhysicalDnsDomain = 6

  Add-Type -TypeDefinition @"
  using System;
  using System.Runtime.InteropServices;

  namespace ComputerSystem {
      public class Identification {
          [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
          static extern bool SetComputerNameEx(int NameType, string lpBuffer);

          public static bool SetPrimaryDnsSuffix(string suffix) {
              try {
                  return SetComputerNameEx($ComputerNamePhysicalDnsDomain, suffix);
              }
              catch (Exception) {
                  return false;
              }
          }
      }
  }
"@
  [ComputerSystem.Identification]::SetPrimaryDnsSuffix($Suffix)
}

$success = Set-PrimaryDnsSuffix "#{domainname}"
if ($success -eq $True) {exit 0} else {exit 1}
    END_OF_POWERSHELL

    @machine.communicate.sudo(powershell)
  end

  # FIXME: de-duplicate with the facts implementation.
  def sudo(cmd)
    stdout = ''
    stderr = ''

    retval = @machine.communicate.sudo(cmd) do |type, data|
      if type == :stderr
        stderr << data
      else
        stdout << data
      end
    end

    {:stdout => stdout, :stderr => stderr, :retval => retval}
  end
end
