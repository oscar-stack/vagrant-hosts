require 'tempfile'

# Guest capability for syncing /etc/hosts on POSIX systems
#
# @since 2.0.0
class VagrantHosts::Cap::SyncHosts::POSIX < VagrantHosts::Cap::SyncHosts::Base

  private

  def update_hosts
    hosts_content = format_hosts
    upload_temphosts(hosts_content, '/tmp/vagrant-hosts.txt')

    # Switch to PTY mode as this provider may execute across multiple machines
    # which may not have requiretty set to false (i.e. because they're still
    # booting and scripts that disable requiretty haven't run yet). Not doing
    # this can have nasty side effects --- such as preventing machines from
    # being destroyed.
    old_pty_setting = @machine.config.ssh.pty
    @machine.config.ssh.pty = true

    # NOTE: cat is used here instead of mv to work around issues with
    #       Docker filesystem layers not allowing the creation of a
    #       new file.
    @machine.communicate.sudo('cat /tmp/vagrant-hosts.txt > /etc/hosts')
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
