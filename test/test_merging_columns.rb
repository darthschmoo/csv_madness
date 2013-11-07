require 'helper'

class TestMergingColumns < MadTestCase
  context "with a simple spreadsheet loaded" do
    setup do
      set_spreadsheet_paths
      load_simple_spreadsheet
    end
    
    teardown do
      
    end   
    
    should "merge :age column into :born column, and drop :born column" do
      @simple.merge_columns( :age, :born )
      assert @simple.columns.include?( :born )
      assert !@simple.columns.include?( :age )
      
      load_mary
      assert_equal "27", @mary.born
    end
    
    should "merge :age column into :born column, and keep :born column" do
      @simple.merge_columns( :age, :born, :drop_source => false )
      assert @simple.columns.include?( :born )
      assert @simple.columns.include?( :age )
      
      load_mary
      assert_equal "27", @mary.born      
    end
    
    should "concatanate first and last names" do
      @simple.concatenate( :fname, :lname, :separator => " " )
      @simple.rename_column( :fname, :full_name )
      
      load_darwin
      assert_equal "Charles Darwin", @darwin.full_name
    end
  end
end