$:.unshift File.expand_path("../lib", __FILE__)
require "vulcan/version"

Gem::Specification.new do |gem|
  gem.name    = "vulcan"
  gem.version = Vulcan::VERSION

  gem.author      = "David Dollar"
  gem.email       = "ddollar@gmail.com"
  gem.homepage    = "http://vulcan.com/"
  gem.summary     = "Build software in the cloud"
  gem.description = gem.summary
  gem.executables = "vulcan"

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|server/|spec/|test/)} }

  gem.add_dependency "heroku",         "~> 2.20.0"
  gem.add_dependency "multipart-post", "~> 1.1.3"
  gem.add_dependency "rest-client",    "~> 1.6.7"
  gem.add_dependency "thor",           "~> 0.14.6"

  gem.post_install_message = "Please run 'vulcan update' to update your build server."
end
