# Provide a base class for syncing hosts entries on POSIX systems.

require 'tempfile'

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

    # Switch to PTY mode as this provider may execute across multiple machines
    # which may not have requiretty set to false (i.e. because they're still
    # booting and scripts that disable requiretty haven't run yet). Not doing
    # this can have nasty side effects --- such as preventing machines from
    # being destroyed.
    old_pty_setting = @machine.config.ssh.pty
    @machine.config.ssh.pty = true

    @machine.communicate.sudo('cat /tmp/hosts > /etc/hosts')
  ensure
    @machine.config.ssh.pty = old_pty_setting
  end

  # Generates content appropriate for a linux hosts file
  #
  # @return [String] All hosts in the config joined into hosts records
  def format_hosts
    all_hosts(@config).inject('') do |str, (address, aliases)|
      str << "#{address} #{aliases.join(' ')}\n"
    end
  end

end
