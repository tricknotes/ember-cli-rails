source "https://rubygems.org"

gemspec

rails_version = ENV.fetch("RAILS_VERSION", "7.2")

if rails_version == "main"
  rails_constraint = { github: "rails/rails" }
else
  rails_constraint = "~> #{rails_version}.0"
end

gem "rails", rails_constraint
gem "high_voltage", "~> 3.0.0"
gem "selenium-webdriver", ">= 4.11"
gem "webrick"

if rails_version == "main"
  # The released rspec-rails series mutates internals that Rails main
  # freezes, failing the suite while loading the specs. Until a release
  # carries the fixes (e.g. https://github.com/rspec/rspec-rails/pull/2915),
  # test against rspec-rails main.
  gem "rspec-rails", github: "rspec/rspec-rails", branch: "main"
end
