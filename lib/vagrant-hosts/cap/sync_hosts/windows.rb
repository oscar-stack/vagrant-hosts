# Provide a base class for syncing hosts entries on Windows systems.
class VagrantHosts::Cap::SyncHosts::Windows < VagrantHosts::Cap::SyncHosts::Base

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
    safechars = name.gsub(%r{[\\/.@*,"]}, '-')

    safename = if (safechars.length > 15)
                firstname = name.split(%r{[\\/.@*,"]}).first
                firstname.length > 0 ? firstname : safechars.truncate(15)
              else
                safechars
              end

    super(safename)
  end

end
