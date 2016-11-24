# encoding: utf-8
require 'fun_with_gems'
require_relative File.join( "lib", "csv_madness" )

FunWith::Gems::Rakefile.setup CsvMadness, self

FunWith::Gems::Rakefile.specification do |gem|
    # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
    # dependencies defined in Gemfile
      gem.name = "csv_madness"
      gem.homepage = "http://github.com/darthschmoo/csv_madness"
      gem.license = "MIT"
      gem.summary = "CSV Madness turns your CSV rows into happycrazy objects."
      gem.description = "CSV Madness removes what little pain is left from Ruby's CSV class.  Load a CSV file, and get back an array of objects with customizable getter/setter methods."
      gem.email = "keeputahweird@gmail.com"
      gem.authors = ["Bryce Anderson"]

      # dependencies defined in Gemfile
      gem.files = Dir.glob( File.join( ".", "lib", "**", "*.rb" ) ) +
                  Dir.glob( File.join( ".", "test", "**", "*" ) ) +
                  %w( Gemfile Rakefile LICENSE.txt README.rdoc VERSION CHANGELOG.markdown ) 
                  # csv_madness.gemspec )
end

FunWith::Gems::Rakefile.setup_gem_boilerplate

#
#
# require 'rubygems'
# require 'bundler'
#
# begin
#   Bundler.setup(:default, :development)
# rescue Bundler::BundlerError => e
#   $stderr.puts e.message
#   $stderr.puts "Run `bundle install` to install missing gems"
#   exit e.status_code
# end
#
# require 'rake'
#
# require 'jeweler'
#
# Jeweler::Tasks.new do |gem|
#   # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
#   gem.name = "csv_madness"
#   gem.homepage = "http://github.com/darthschmoo/csv_madness"
#   gem.license = "MIT"
#   gem.summary = "CSV Madness turns your CSV rows into happycrazy objects."
#   gem.description = "CSV Madness removes what little pain is left from Ruby's CSV class.  Load a CSV file, and get back an array of objects with customizable getter/setter methods."
#   gem.email = "keeputahweird@gmail.com"
#   gem.authors = ["Bryce Anderson"]
#
#   # dependencies defined in Gemfile
#   gem.files = Dir.glob( File.join( ".", "lib", "**", "*.rb" ) ) +
#               Dir.glob( File.join( ".", "test", "**", "*" ) ) +
#               %w( Gemfile Rakefile LICENSE.txt README.rdoc VERSION CHANGELOG.markdown csv_madness.gemspec )
#
# end
#
# Jeweler::RubygemsDotOrgTasks.new
#
# require 'rake/testtask'
# Rake::TestTask.new(:test) do |test|
#   test.libs << 'lib' << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
# end
#
# # require 'rcov/rcovtask'
# # Rcov::RcovTask.new do |test|
# #   test.libs << 'test'
# #   test.pattern = 'test/**/test_*.rb'
# #   test.verbose = true
# #   test.rcov_opts << '--exclude "gems/*"'
# # end
#
# task :default => :test
#
# require 'rdoc/task'
# Rake::RDocTask.new do |rdoc|
#   version = File.exist?('VERSION') ? File.read('VERSION') : ""
#
#   rdoc.rdoc_dir = 'rdoc'
#   rdoc.title = "csv_madness #{version}"
#   rdoc.rdoc_files.include('README*')
#   rdoc.rdoc_files.include('lib/**/*.rb')
# end
