source 'http://rubygems.org'

def darwin?
  RbConfig::CONFIG['host_os'] =~ /darwin/
end

def windows_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /mingw|mswin/i ? require_as : false
end

def linux_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /linux/ ? require_as : false
end
# Mac OS X
def darwin_only(require_as)
  RbConfig::CONFIG['host_os'] =~ /darwin/ ? require_as : false
end

gem 'activerecord', '~> 4.1'

group :test, :development do
gem 'pry'
  gem 'pry-pretty-numeric'
  gem 'pry-highlight'
  # step, next, finish, continue, break
  gem 'pry-nav'
  gem 'pry-doc'
  gem 'pry-docmore'

  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'factory_girl'
  gem 'rb-fsevent', require: darwin_only('rb-fsevent')
  gem 'ruby_gntp'
  gem 'growl', require: darwin_only('growl')
  gem 'rb-inotify', require: linux_only('rb-inotify')
  # gem 'rb-readline', require: darwin_only('rb-readline')
  gem 'rspec'
  gem 'spring'
  gem 'spring-commands-rspec'

  # if RUBY_PLATFORM =~ /darwin/
  #  gem 'rb-fsevent', '~> 0.9.1', require: false
  #  gem 'ruby_gntp'
  # end
  gem 'listen', '~> 2.7.12'
  gem 'guard', '~> 2.8'
  gem 'terminal-notifier-guard', '~> 1.6.1',  require: darwin_only('terminal-notifier-guard')

  gem 'database_cleaner'

  gem 'guard-rspec'
  gem 'guard-rails'
  gem 'guard-shell'
  gem 'guard-bundler'
  gem 'guard-ctags-bundler'
  gem 'guard-rubocop'
end
