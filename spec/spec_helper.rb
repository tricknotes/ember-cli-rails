# CI pipes the suite's output through rake, which block-buffers it: flush
# progress as it happens, so a slow or stuck job shows where it stopped.
$stdout.sync = true

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

ENV["RAILS_ENV"] = "test"

require "dummy/application"
require "rspec/rails"

Dummy::Application.initialize!

Dir["spec/support/**/*.rb"].sort.each { |file| require "./#{file}" }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.infer_spec_type_from_file_location!
  config.order = :random
end
