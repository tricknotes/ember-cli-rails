require "rubygems"
require "bundler/setup"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

task(:default).clear
task default: :spec

if defined? RSpec
  task(:spec).clear
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = false
  end
end
