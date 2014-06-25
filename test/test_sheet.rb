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
      assert_raises(RuntimeError) do
        CsvMadness::Sheet.add_search_path( CsvMadness.root.join("rocaganthor") )
      end
    end
    
    should "check a search path for files to load" do
      sheet = CsvMadness.load( "with_nils.csv" )
      assert sheet.is_a?(CsvMadness::Sheet)
    end
  end
  
  context "testing column_types" do
    should "gracefully handle empty strings for all column_types" do
      sheet = CsvMadness.load("test_column_types.csv")
      
      for type, ignore_proc in CsvMadness::Sheet::COLUMN_TYPES
        sheet.set_column_type( type, type )
      end
      
      record = sheet.records[0]
      
      assert_kind_of String, record.date
      assert_equal nil, record.number
      assert_equal nil, record.float
      
      record = sheet.records[1]
      assert_equal "12", record.id
      assert_equal 134.2, record.number
      assert_equal 100, record.integer
      assert_equal Time.parse("2013-01-13"), record.date
    end
  end
  
  context "testing add/remove records" do
    setup do
      @sheet = CsvMadness.load( "simple.csv", :index => :id )
    end
    
    should "add record" do
      count = @sheet.records.length
      @sheet.add_record( @sheet.records.first.to_hash )
      assert_equal count + 1, @sheet.records.length
      
      for method in [:id, :fname, :lname, :age, :born]
        assert_equal @sheet.records.first.send(method), @sheet.records.last.send(method)
      end
    end
    
    should "test remove_record" do
      count = @sheet.records.length
      record = @sheet.records.last
      record_id = record.id
      
      assert @sheet.fetch(:id, record_id) != nil
      
      
      @sheet.remove_record( record )
      assert_equal (count - 1), @sheet.records.length
      assert @sheet.fetch(:id, record_id) == nil
      
      count = @sheet.records.length
      record = @sheet.records[0]
      record_id = record.id
      
      @sheet.remove_record( 0 )
      assert_nil @sheet.fetch(:id, record_id)
      assert_equal (count - 1), @sheet.records.length
    end
  end
  
  context "testing blanking and splitting of spreadsheet" do
    should "deliver me a properly blanked spreadsheet (simple)" do
      sheet = CsvMadness.load( "splitter.csv" )
      blank_sheet = sheet.blanked
      
      sheet.length.times do |i|
        blank_sheet.add_record( sheet.remove_record( 0 ) )
      end
      
      assert_zero sheet.length
      assert_equal 10, blank_sheet.length
      assert_nil blank_sheet.spreadsheet_file
    end

    should "deliver me a properly blanked spreadsheet (index)" do
      sheet = CsvMadness.load( "splitter.csv", :index => [:id] )
      blank_sheet = sheet.blanked
    end
    
    should "split splitter" do
      sheet = CsvMadness.load( "splitter.csv", :index => [:id, :party] )
      
      sheets = sheet.split(&:party)
      
      for party in %w(D I R)
        assert_equal_length sheets[party], sheet.records.select{|r| r.party == party }
      end
      
      assert_includes sheets["D"].index_columns, :id
      assert_includes sheets["I"].index_columns, :party
    end
  end
  
  context "testing hilarious spreadsheet fails" do
    should "raise error on forbidden column name" do
      assert_raises(RuntimeError) do
        sheet = CsvMadness.load( "forbidden_column.csv" )
      end
    end
  end
end
