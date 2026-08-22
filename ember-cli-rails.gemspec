# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ember_cli/version"

Gem::Specification.new do |spec|
  spec.name     = "ember-cli-rails"
  spec.version  = EmberCli::VERSION.dup
  spec.authors  = ["Pavel Pravosud", "Jonathan Jackson", "Sean Doyle", "Ryunosuke Sato"]
  spec.email    = ["pavel@pravosud.com", "jonathan.jackson1@me.com", "sean.p.doyle24@gmail.com", "tricknotes.rs@gmail.com"]
  spec.summary  = "Integration between Ember CLI and Rails"
  spec.homepage = "https://github.com/tricknotes/ember-cli-rails"
  spec.license  = "MIT"
  spec.files    = Dir["README.md", "CHANGELOG.md", "LICENSE.txt", "{lib,app,config}/**/*"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "ember-cli-rails-assets", ">= 0.8.0", "< 1.0"
  spec.add_dependency "railties", ">= 4.2"
  spec.add_dependency "rack", ">= 2.1", "< 4.0"
  spec.add_dependency "terrapin", "~> 0.6.0"
  spec.add_dependency "html_page", "~> 0.1.0"

  spec.add_development_dependency "generator_spec", "~> 0.9.0"
  spec.add_development_dependency "rspec-rails", ">= 3.6.0", "< 7.0"

  spec.add_development_dependency "capybara-selenium"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.6.0"
end
