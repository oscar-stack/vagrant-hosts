source 'https://rubygems.org'
require 'rubygems/version'

vagrant_branch = ENV['TEST_VAGRANT_VERSION'] || 'v1.9.8'
vagrant_version = nil

# Wrapping gemspec in the :plugins group causes Vagrant 1.5 and newer to
# automagically load this plugin during acceptance tests.
group :plugins do
  gemspec
end

group :development do
  gem 'yard', '~> 0.9.11'
  gem 'redcarpet'
end

group :test do
  case vagrant_branch
  when /head/i
    gem 'vagrant', :git => 'https://github.com/hashicorp/vagrant.git',
      :branch => 'master'
  else
    vagrant_version = Gem::Version.new(vagrant_branch.sub(/^v/, ''))
    gem 'vagrant', :git => 'https://github.com/hashicorp/vagrant.git',
      :tag => vagrant_branch
    # FIXME: Hack to allow Vagrant v1.6.5 to install for tests. Remove when
    # support for 1.6.5 is dropped.
    gem 'rack', '< 2'
  end

  if vagrant_branch.match(/head/i) || (vagrant_version > Gem::Version.new('1.9.3'))
    # Pinned on 4/11/2017. Compatible with Vagrant > 1.9.3.
    gem 'vagrant-spec', :git => 'https://github.com/hashicorp/vagrant-spec.git',
      :ref => '1d09951'
  elsif vagrant_version
    # Pinned on 12/10/2014. Compatible with Vagrant 1.6.x -- 1.9.3.
    gem 'vagrant-spec', :git => 'https://github.com/hashicorp/vagrant-spec.git',
      :ref => '1df5a3a'
  end
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"
