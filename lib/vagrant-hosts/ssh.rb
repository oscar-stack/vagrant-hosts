require 'vagrant'
require 'vagrant/errors'
require 'vagrant/communication/ssh'

# Helloooooo monkey patching.

class Vagrant::Communication::SSH

  # Download a remote file
  #
  # @param [String] from the path on the remote end
  # @param [String] to   the path on the local end
  #
  #
  def download(from, to)
    @logger.debug("Downlaoding: #{from} to #{to}")

    connect do |connection|
      scp = Net::SCP.new(connection)
      scp.download!(from, to)
    end

  rescue Net::SCP::Error => e
    raise Vagrant::Errors::SCPUnavailable if e.message =~ /\(127\)/
    raise
  end
end
