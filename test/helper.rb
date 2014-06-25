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
# require 'test/unit'
# require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'fun_with_testing'
require 'csv_madness'

# class Test::Unit::TestCase
# end

class MadTestCase < FunWith::Testing::TestCase # Test::Unit::TestCase
  include FunWith::Testing::Assertions::Basics
  
  MARY_ID = "1"
  BILL_ID = "2"
  DARWIN_ID = "3"
  CHUCK_ID = "4"

  def setup
    set_spreadsheet_paths
  end
  
  def load_mary
    id = @simple.index_columns.first
    @mary = @simple.fetch( id, MARY_ID )
  end
  
  def load_bill
    id = @simple.index_columns.first
    @bill = @simple.fetch( id, BILL_ID )
  end
  
  def load_darwin
    id = @simple.index_columns.first
    @darwin = @simple.fetch( id, DARWIN_ID )
  end
  
  def load_chuck
    id = @simple.index_columns.first
    @chuck = @simple.fetch( id, CHUCK_ID )
  end
     
  def set_person_records
    load_mary
    load_darwin
    load_bill
    load_chuck
  end
  
  def muck_up_spreadsheet
    @simple.add_column(:scrambled_name) do |val, record|
      record.fname.chars.map(&:to_s).zip( record.lname.chars.map(&:to_s) ).flatten.compact.join
    end
    
    @simple.alter_column(:id) do |val|
      (val.to_i << 8) % 27
    end
    
    @simple.set_column_type(:id, :float)
    @simple.set_column_type(:born, :date)
    
    @simple.alter_column(:born) do |val|
      if val.is_a?(String)
        -1.0
      else
        (Time.now - val).to_f
      end
    end

    @simple.drop_column(:fname)
    @simple.drop_column(:lname)
  end
   
  def set_spreadsheet_paths
    @csv_load_path = CsvMadness.root( "test", "csv" )
    @csv_output_path = CsvMadness.root( "test", "csv", "out" )
    CsvMadness::Sheet.add_search_path( @csv_load_path )
    CsvMadness::Sheet.add_search_path( @csv_output_path )
  end
  
  def load_simple_spreadsheet
    @simple = CsvMadness.load( "simple.csv", index: [:id] )
  end
  
  def unload_simple_spreadsheet
    @simple = nil
  end
  
  def empty_output_folder
    if defined?(FileUtils)
      FileUtils.rm_rf( Dir.glob( @csv_output_path.join("**","*") ) )
    else
      puts "fileutils not defined"
      `rm -rf #{@csv_output_path.join('*')}`
    end
  end
end