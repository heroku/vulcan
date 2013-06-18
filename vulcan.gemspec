$:.unshift File.expand_path("../lib", __FILE__)
require "vulcan/version"

Gem::Specification.new do |gem|
  gem.name    = "vulcan"
  gem.version = Vulcan::VERSION

  gem.authors      = ["David Dollar", "Zeke Sikelianos"]
  gem.email       = ["ddollar@gmail.com", "zeke@sikelianos.com"]
  gem.homepage    = "https://github.com/heroku/vulcan"
  gem.summary     = "Build software in the cloud"
  gem.description = gem.summary
  gem.executables = "vulcan"

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|data/|ext/|lib/|server/|spec/|test/)} }

  gem.add_dependency "heroku",         ">= 2.26.0", "< 3.0"
  gem.add_dependency "multipart-post", "~> 1.2.0"
  gem.add_dependency "rest-client",    "~> 1.6.7"
  gem.add_dependency "thor",           "~> 0.14.6"

  gem.post_install_message = "Please run 'vulcan update' to update your build server."
end
