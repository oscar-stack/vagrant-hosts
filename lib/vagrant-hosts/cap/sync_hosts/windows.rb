# Provide a base class for syncing hosts entries on Windows systems.
class VagrantHosts::Cap::SyncHosts::Windows < VagrantHosts::Cap::SyncHosts::Base

  def update_hosts
    host_entries = []
    all_hosts.each do |(address, aliases)|
      aliases.each do |name|
        host_entries << "#{address} #{name}"
      end
    end

    script = []
    script << '$HostsLocation = "$env:windir\\System32\\drivers\\etc\\hosts";'

    host_entries.each do |entry|
      script << "\$HostEntry = \"#{entry}\""
      script << "if (!((gc \$HostsLocation) -contains $HostEntry)) { Add-Content -Path $HostsLocation -Value $HostEntry; }"
    end

    @machine.communicate.sudo(script.join("\r\n"))
  end

end
