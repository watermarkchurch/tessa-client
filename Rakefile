require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

task :environment do
  require 'dotenv'
  Dotenv.load

  $LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
  require 'tessa'
end

desc "Launch a pry shell with Tessa library loaded"
task :pry => :environment do
  require 'pry'
  Pry.start
end

namespace :build do
  task :js do
    system("yarn build")
  end
end

Rake::Task['build'].enhance ['build:js']
