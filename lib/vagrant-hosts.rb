module VagrantHosts
  require 'vagrant-hosts/version'
  require 'vagrant-hosts/plugin'
end

I18n.load_path << File.expand_path('../templates/locales/en.yml', File.dirname(__FILE__))
