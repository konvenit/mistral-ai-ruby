# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Run all tests and linting"
task test: %i[spec rubocop]

desc "Build the gem"
task build: :test do
  Rake::Task["build"].invoke
end

desc "Install the gem locally"
task install: :build do
  Rake::Task["install"].invoke
end

desc "Push the gem to RubyGems"
task release: :build do
  Rake::Task["release"].invoke
end

task default: :test
