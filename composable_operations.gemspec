# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'composable_operations/version'

Gem::Specification.new do |spec|
  spec.name          = "composable_operations"
  spec.version       = ComposableOperations::VERSION
  spec.authors       = ["Konstantin Tennhard"]
  spec.email         = ["me@t6d.de"]
  spec.summary       = %q{Tool set for operation pipelines.}
  spec.description   = %q{Composable Operations is a tool set for creating operations and assembling
multiple of these operations in operation pipelines.}
  spec.homepage      = "http://github.com/t6d/composable_operations"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "smart_properties", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry", "~> 0.9.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.99"
end
