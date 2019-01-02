# Guest capability for updating System32/drivers/etc/hosts on Windows
#
# @since 2.0.0
class VagrantHosts::Cap::SyncHosts::Windows < VagrantHosts::Cap::SyncHosts::Base

  private

  def update_hosts
    host_entries = []
    all_hosts(@config).each do |(address, aliases)|
      aliases.each do |name|
        host_entries << "#{address} #{name}"
      end
    end

    script = []
    script << '$HostsPath = "$env:windir\\System32\\drivers\\etc\\hosts"'
    script << '$Hosts = gc $HostsPath'

    host_defs = "'" + host_entries.join('\', \'') + "'"
    script << "@(#{host_defs}) | % { if (\$Hosts -notcontains \$_) { Add-Content -Path \$HostsPath -Value \$_ }}"

    @machine.communicate.sudo(script.join("; "))
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
end
