require 'helper'

class TestCsvMadness < MadTestCase
  context "with a simple spreadsheet loaded" do
    setup do
      set_spreadsheet_paths
      load_simple_spreadsheet
      set_person_records
    end
    
    should "reset spreadsheet by reloading from file" do
      assert @mary.respond_to?(:lname)
      assert @darwin.respond_to?(:fname)
      assert @mary.born.is_a?(String)
      
      debugger
      muck_up_spreadsheet
      set_person_records
      
      assert !@mary.respond_to?(:lname)
      assert !@darwin.respond_to?(:fname)
      assert @mary.born.is_a?(Float)
      
      @simple.reload_spreadsheet
      set_person_records
      
      assert @mary.respond_to?(:lname)
      assert @darwin.respond_to?(:fname)
    end
  end
end