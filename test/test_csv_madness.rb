require 'helper'

class TestCsvMadness < Test::Unit::TestCase
  context "all:" do
    setup do
      @csv_search_path = Pathname.new( __FILE__ ).dirname.join("csv")
      @csv_output_path = @csv_search_path.join("out")
      CsvMadness::Sheet.add_search_path( @csv_search_path )
    end

    teardown do
      if defined?(FileUtils)
        FileUtils.rm_rf( Dir.glob( @csv_output_path.join("**","*") ) )
      else
        puts "fileutils not defined"
        `rm -rf #{@csv_output_path.join('*')}`
      end
    end
    
    context "testing sheet basics" do
      should "not accept duplicate search paths" do
        CsvMadness::Sheet.add_search_path( Pathname.new( __FILE__ ).dirname.join("csv") )
        assert_equal 1, CsvMadness::Sheet.instance_variable_get("@search_paths").length
      end
    
      should "load a simple spreadsheet" do
        simple = CsvMadness::Sheet.from("simple.csv")
        assert_equal "Mary", simple[0].fname
        assert_equal "Paxton", simple[1].lname
        assert_equal "72", simple[2].age
        assert_equal "1", simple[0].id
        assert_equal [:id, :fname, :lname, :age, :born], simple.columns
        assert_equal [:id, :fname, :lname, :age, :born], simple[0].columns
      end
    
      should "index records properly on a simple spreadsheet, using custom columns" do
        simple = CsvMadness.load( "simple.csv", 
                                  columns: [:index, :given_name, :surname, :years_old, :born], 
                                  index: [:index] )
        bill = simple.fetch(:index, "2")
        mary = simple.fetch(:index, "1")
      
        assert_equal "Bill", bill.given_name
        assert_equal "Moore", mary.surname
        assert_equal "1", mary.index
      end
    end
  
    context "testing transformations" do
      context "with a simple spreadsheet loaded" do
        setup do
          @simple = CsvMadness.load( "simple.csv", index: [:id] )
        end
      
        teardown do
          @simple = nil
        end
      
        should "transform every cell" do
          @simple.alter_cells do |cell|
            cell = "*#{cell}*"
          end
        
          bill = @simple.fetch(:id, "2")
          mary = @simple.fetch(:id, "1")
        
          assert_equal "*Bill*", bill.fname
          assert_equal "*Moore*", mary.lname
          assert_equal "*1*", mary.id
        end
      
        should "transform every cell, accessing the whole record" do
          @simple.alter_cells do |cell, record|
            cell == record.id ? record.id : "#{record.id}: #{cell}"
          end
        
          bill = @simple.fetch(:id, "2")
          mary = @simple.fetch(:id, "1")

          assert_equal "2: Bill", bill.fname
          assert_equal "1: Moore", mary.lname
          assert_equal "1", mary.id
        end
      
        should "transform id column using alter_column" do
          @simple.alter_column(:id) do |id|
            (id.to_i * 2).to_s
          end
        
          assert_equal %W(2 4 6 8), @simple.column(:id)
        end
      
        should "set ID column to integers" do
          @simple.set_column_type(:id, :integer)
        
          @simple.records.each do |record|
            assert_kind_of Integer, record.id
            assert_includes [1,2,3,4], record.id
          end
        end
      
        should "parse a date column with one invalid date" do
          @simple.set_column_type( :born, :date )
          born1 = @simple[0].born
          born3 = @simple[2].born
          assert_kind_of Time, born1
          assert_in_delta Time.parse("1986-04-08"), born1, 3600 * 24
        
          assert_kind_of String, born3
          assert_match /Invalid Time Format/, born3
        end
      
        should "successfully decorate record objects with new functionality" do
          moduul = Module.new do
            def full_name
              "#{self.fname} #{self.lname}"
            end
          
            def name_last_first
              "#{self.lname}, #{self.fname}"
            end
          end
        
          @simple.add_record_methods( moduul )
        
          assert @simple[0].respond_to?( :full_name )
          assert_equal "Mary Moore", @simple[0].full_name
          assert @simple[0].respond_to?( :name_last_first )
          assert_equal "Moore, Mary", @simple[0].name_last_first
        end
      
        should "add methods to record objects (block form)" do
          @simple.add_record_methods do
            def full_name
              "#{self.fname} #{self.lname}"
            end
          end
        
          assert @simple[0].respond_to?( :full_name )
          assert_equal "Mary Moore", @simple[0].full_name
        end
      
        should "return an array of objects when feeding fetch() an array" do
          records = @simple.fetch(:id, ["1","2"])
          assert_equal records.length, records.compact.length
          assert_equal 2, records.length
          assert_equal "1", records.first.id
        end
      end
    end
  
    context "loading nil spreadsheet" do
      setup do
        @nilsheet = CsvMadness.load( "with_nils.csv", index: [:id] )
      end
      
      should "stomp away the nils" do
        @norris = @nilsheet.fetch(:id, "4")
        assert_equal nil, @norris.born
        assert_equal "Chuck", @norris.fname
      
        @nilsheet.nils_are_blank_strings  # should turn every nil into a ''
        assert_equal "", @norris.born
        assert_equal "Chuck", @norris.fname
      end
      
      should "to_csv properly" do
        @to_csv = @nilsheet.to_csv( force_quotes: true )
        assert_match /"Moore"/, @to_csv
        assert_match /"age","born"/, @to_csv
      end
      
      should "write to an output file properly" do
        @outfile = @csv_output_path.join("output_nilfile.csv")
        @nilsheet.write_to_file( @outfile, force_quotes: true )
        
        assert File.exist?( @outfile )
        @to_csv = File.read( @outfile )
        assert_match /"Moore"/, @to_csv
        assert_match /"age","born"/, @to_csv
      end
    end
  end
end
