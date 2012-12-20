# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'skywatch/version'

Gem::Specification.new do |gem|
  gem.name          = "skywatch"
  gem.version       = Skywatch::VERSION
  gem.authors       = ["Jeff Lindsay"]
  gem.email         = ["progrium@gmail.com"]
  gem.description   = %q{Simple, Unix-oriented alerting system that lets you define checks and alerts in any language and then magically runs them on Heroku.}
  gem.summary       = %q{Simple, Unix-oriented alerting system}
  gem.homepage      = "http://github.com/progrium/skywatch"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rspec", "~> 2.6"

  gem.add_dependency "commander", "~> 4.1"
  gem.add_dependency "heroku", "~> 2.33"
end
