# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lotus/mongodb/version'

Gem::Specification.new do |spec|
  spec.name          = "lotus-mongodb"
  spec.version       = Lotus::Model::Adapters::Mongodb::VERSION
  spec.authors       = ["Yonderbound"]
  spec.email         = ["info@yonderbound.com"]
  spec.summary       = %q{MongoDB adapter for lotus-model}
  spec.homepage      = "http://github.com/yonderbound/lotus-mongodb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "lotus-model", '~> 0.5.0'
  spec.add_development_dependency "minitest", '~> 5'
  spec.add_dependency "mongo", "~> 2.1.2"
end
