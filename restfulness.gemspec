# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'restfulness/version'

Gem::Specification.new do |spec|
  spec.name          = "restfulness"
  spec.version       = Restfulness::VERSION
  spec.authors       = ["Sam Lown"]
  spec.email         = ["me@samlown.com"]
  spec.description   = %q{Simple REST server that focuses on resources instead of routes.}
  spec.summary       = %q{Use to create a powerful, yet simple REST API in your application.}
  spec.homepage      = "https://github.com/samlown/restfulness"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 1.5", "< 2.1"
  spec.add_dependency "multi_json", "~> 1.8"
  spec.add_dependency "activesupport", ">= 4.0", "< 6.0"
  spec.add_dependency "http_accept_language", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
