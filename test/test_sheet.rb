require 'helper'

class TestSheet < MadTestCase
  context "testing getter_name()" do
    should "return proper function names" do
      assert_equal :hello_world, CsvMadness::Sheet.getter_name( "  heLLo __ world " )
      assert_equal :_0_hello_world, CsvMadness::Sheet.getter_name( "0  heLLo __ worlD!!! " )
    end
  end
  
  context "testing default spreadsheet paths" do
    should "only load existing paths" do
      assert_raise(RuntimeError) do
        CsvMadness::Sheet.add_search_path( CsvMadness.root.join("rocaganthor") )
      end
    end
    
    should "check a search path for files to load" do
      CsvMadness::Sheet.add_search_path( CsvMadness.root.join("test", "csv") )
      sheet = CsvMadness.load( "with_nils.csv" )
      assert sheet.is_a?(CsvMadness::Sheet)
    end
  end
  
  context "testing column_types" do
    setup do
      CsvMadness::Sheet.add_search_path( CsvMadness.root.join("test", "csv") )
    end
  
    should "gracefully handle empty strings for all column_types" do
      sheet = CsvMadness.load("test_column_types.csv")
      
      for type, ignore_proc in CsvMadness::Sheet::COLUMN_TYPES
        sheet.set_column_type( type, type )
      end
      
      record = sheet.records[0]
      
      assert_kind_of String, record.date
      assert_equal nil, record.number
      assert_equal nil, record.float
    end
  end
end
