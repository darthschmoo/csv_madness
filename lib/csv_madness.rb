require 'csv'
require 'fun_with_gems'
# require 'fun_with_version_strings'
require 'time'        # to use Time.parse to parse cells to get the date

lib_dir = __FILE__.fwf_filepath.dirname
FunWith::Gems.make_gem_fun( "CsvMadness", :require => lib_dir.join( "csv_madness" ) )

