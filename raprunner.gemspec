# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'raprunner/version'

Gem::Specification.new do |spec|
  spec.name          = "raprunner"
  spec.version       = Raprunner::VERSION
  spec.authors       = ["Robert Byrne"]
  spec.email         = ["robert@byrnemail.org"]
  spec.summary       = %q{Manage long running processes}
  spec.description   = %q{Use ruby to define a set of long running processes, restart policy, notifications and suchlike}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = ["raprunner"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_dependency "rainbow"
end
