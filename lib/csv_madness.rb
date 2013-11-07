require 'csv'
require 'fun_with_files'
require 'time'        # to use Time.parse to parse cells to get the date
require 'debugger'

require_relative 'csv_madness/data_accessor_module'
require_relative 'csv_madness/sheet'
require_relative 'csv_madness/record'


FunWith::Files::RootPath.rootify( CsvMadness, __FILE__.fwf_filepath.dirname.up )

CsvMadness.class_eval do
  def self.load( csv, opts = {} )
    CsvMadness::Sheet.from( csv, opts )
  end
end
