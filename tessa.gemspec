# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tessa/version'

Gem::Specification.new do |spec|
  spec.name          = "tessa"
  spec.version       = Tessa::VERSION
  spec.authors       = ["Justin Powell", "Travis Petticrew"]
  spec.email         = ["jpowell@watermark.org", "tpetticrew@watermark.org"]
  spec.summary       = %q{Manage your assets.}
  spec.description   = %q{Manage your assets.}
  spec.homepage      = "https://github.com/watermarkchurch/tessa-client"
  spec.license       = "MIT"

  spec.required_ruby_version = '~> 2.3'

  spec.files         = `git ls-files -z`.split("\x0").push(
    'app/assets/javascripts/tessa.js',
    'app/assets/javascripts/tessa.esm.js',
  )
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.4"
  spec.add_development_dependency "simplecov", "~> 0.15.1"
  spec.add_development_dependency "rails", "~> 6"
  spec.add_development_dependency 'sqlite3', '~> 1.4'
  spec.add_development_dependency 'listen'
end
