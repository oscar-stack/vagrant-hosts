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

end
