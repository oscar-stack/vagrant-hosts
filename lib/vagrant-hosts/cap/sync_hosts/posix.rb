# Provide a base class for syncing hosts entries on POSIX systems.
class VagrantHosts::Cap::SyncHosts::POSIX < VagrantHosts::Cap::SyncHosts::Base

  private

  def upload_tmphosts
    cache = Tempfile.new('tmp-hosts')
    cache.write(format_hosts)
    cache.flush
    @machine.communicate.upload(cache.path, '/tmp/hosts')
  end

  def update_hosts
    upload_tmphosts
    @machine.communicate.sudo('install -m 644 /tmp/hosts /etc/hosts')
  end

  # Generates content appropriate for a linux hosts file
  #
  # @return [String] All hosts in the config joined into hosts records
  def format_hosts
    all_hosts.inject('') do |str, (address, aliases)|
      str << "#{address} #{aliases.join(' ')}\n"
    end
  end

end
