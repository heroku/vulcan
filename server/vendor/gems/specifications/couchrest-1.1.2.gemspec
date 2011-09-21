# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "couchrest"
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["J. Chris Anderson", "Matt Aimonetti", "Marcos Tapajos", "Will Leinweber", "Sam Lown"]
  s.date = "2011-07-22"
  s.description = "CouchRest provides a simple interface on top of CouchDB's RESTful HTTP API, as well as including some utility scripts for managing views and attachments."
  s.email = "jchris@apache.org"
  s.extra_rdoc_files = ["LICENSE", "README.md", "THANKS.md"]
  s.files = ["LICENSE", "README.md", "THANKS.md"]
  s.homepage = "http://github.com/couchrest/couchrest"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Lean and RESTful interface to CouchDB."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, ["~> 1.6.1"])
      s.add_runtime_dependency(%q<mime-types>, ["~> 1.15"])
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.0.0"])
      s.add_development_dependency(%q<json>, ["~> 1.5.1"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
    else
      s.add_dependency(%q<rest-client>, ["~> 1.6.1"])
      s.add_dependency(%q<mime-types>, ["~> 1.15"])
      s.add_dependency(%q<multi_json>, ["~> 1.0.0"])
      s.add_dependency(%q<json>, ["~> 1.5.1"])
      s.add_dependency(%q<rspec>, ["~> 2.6.0"])
    end
  else
    s.add_dependency(%q<rest-client>, ["~> 1.6.1"])
    s.add_dependency(%q<mime-types>, ["~> 1.15"])
    s.add_dependency(%q<multi_json>, ["~> 1.0.0"])
    s.add_dependency(%q<json>, ["~> 1.5.1"])
    s.add_dependency(%q<rspec>, ["~> 2.6.0"])
  end
end
