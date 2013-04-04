require 'csv'
require 'pathname'
require 'time'        # to use Time.parse to parse cells to get the date
require 'debugger'

require_relative 'csv_madness/sheet'
require_relative 'csv_madness/record'

CsvMadness.class_eval do
  def self.load( csv, opts = {} )
    CsvMadness::Sheet.from( csv, opts )
  end
end
