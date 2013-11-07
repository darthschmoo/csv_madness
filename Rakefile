# encoding: utf-8

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'

require 'jeweler'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "csv_madness"
  gem.homepage = "http://github.com/darthschmoo/csv_madness"
  gem.license = "MIT"
  gem.summary = %Q{CSV Madness turns your CSV rows into happycrazy objects.}
  gem.description = %Q{CSV Madness removes what little pain is left from Ruby's CSV class.  Load a CSV file, and get back an array of objects with customizable getter/setter methods.}
  gem.email = "keeputahweird@gmail.com"
  gem.authors = ["Bryce Anderson"]
  # dependencies defined in Gemfile
  gem.files = [ "./lib/csv_madness/data_accessor_module.rb", 
                "./lib/csv_madness/record.rb", 
                "./lib/csv_madness/sheet.rb", 
                "./lib/csv_madness.rb", 
                "./Gemfile",
                "./VERSION",
                "./README.rdoc",
                "./Rakefile",
                "./CHANGELOG.markdown",
                "./test/csv/simple.csv",
                "./test/helper.rb",
                "./test/test_csv_madness.rb",
                "./test/test_sheet.rb" ]
end

Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

# require 'rcov/rcovtask'
# Rcov::RcovTask.new do |test|
#   test.libs << 'test'
#   test.pattern = 'test/**/test_*.rb'
#   test.verbose = true
#   test.rcov_opts << '--exclude "gems/*"'
# end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "csv_madness #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
