$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'vagrant-hosts/version'
require 'date'

Gem::Specification.new do |gem|
  gem.name    = 'vagrant-hosts'
  gem.version = VagrantHosts::VERSION
  gem.date    = Date.today.to_s

  gem.summary     = 'Manage static DNS on vagrant guests'
  gem.description = <<-EOD
    Manage static DNS entries and configuration for Vagrant guests.
  EOD

  gem.authors  = 'Adrien Thebo'
  gem.email    = 'adrien@somethingsinistral.net'
  gem.homepage = 'https://github.com/adrienthebo/vagrant-hosts'

  gem.has_rdoc = true
  gem.license  = 'Apache 2.0'

  gem.files        = %x{git ls-files -z}.split("\0")
  gem.require_path = 'lib'

  # Pinned for compatibility with vagrant-spec.
  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency 'rspec', '~> 2.14.0'
end
