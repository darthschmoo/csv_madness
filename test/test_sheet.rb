require 'helper'

class TestCsvMadness < MadTestCase
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
end
