require 'helper'

class TestCsvMadness < MadTestCase
  context "all:" do
    setup do
      load_simple_spreadsheet
    end

    teardown do
      empty_output_folder
    end
    
    context "testing sheet basics" do
      should "not accept duplicate search paths" do
        @path_count = CsvMadness::Sheet.search_paths.length
        CsvMadness::Sheet.add_search_path( @csv_load_path )
        assert_equal @path_count, CsvMadness::Sheet.search_paths.length
      end
    
      should "load a simple spreadsheet" do
        simple = CsvMadness::Sheet.from( "simple.csv" )
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
          load_simple_spreadsheet
        end
      
        teardown do
          unload_simple_spreadsheet
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
      
        should "set ID column to floats" do
          @simple.set_column_type(:id, :float)
        
          @simple.records.each do |record|
            assert_kind_of Float, record.id
            assert_includes [1.0,2.0,3.0,4.0], record.id
          end
        end
        
        should "parse a date column with one invalid date" do
          @simple.set_column_type( :born, :date )
          born1 = @simple[0].born
          born3 = @simple[2].born
          assert_kind_of Time, born1
          assert_in_delta Time.parse("1986-04-08"), born1, 3600 * 24
        
          assert_kind_of String, born3
          assert_match( /Invalid Time Format/, born3 )
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
        
        should "rename columns" do
          load_mary
          
          assert_equal "Mary", @mary.fname
          assert_equal "Moore", @mary.lname
          assert_equal "Mary", @mary[1]
          assert_equal "Moore", @mary[2]
          
          @simple.rename_column( :fname, :first_name )
          @simple.rename_column( :lname, :last_name )
          
          assert_equal "Mary", @mary.first_name
          assert_equal "Moore", @mary.last_name
          assert_equal "Mary", @mary[1]
          assert_equal "Moore", @mary[2]
        end
        
        should "rename an index column" do
          @simple.rename_column( :id, :identifier )
          @mary = @simple.fetch( :identifier, "1" )
          assert_equal "1", @mary.identifier
        end
        
        should "rename an index column and ensure that the outputted spreadsheet has the new column name" do
          @simple.rename_column( :id, :identifier )
          @outfile = @csv_output_path.join("output.csv")
          @simple.write_to_file( @outfile, force_quotes: true )

          @simple = CsvMadness.load( @outfile, index: [:identifier] )
          
          load_mary
          assert_equal "Mary", @mary.fname
        end
        
        should "filter! records" do
          @simple.filter! do |record|
            record.id == BILL_ID || record.id == CHUCK_ID
          end
          
          assert_equal 2, @simple.records.length
          
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
        assert_match( /"Moore"/, @to_csv )
        assert_match( /"age","born"/, @to_csv )
      end
      
      should "write to an output file properly" do
        # debugger
        @outfile = @csv_output_path.join("output_nilfile.csv")
        @nilsheet.write_to_file( @outfile, force_quotes: true )
        
        assert File.exist?( @outfile )
        @to_csv = File.read( @outfile )
        assert_match( /"Moore"/, @to_csv )
        assert_match( /"age","born"/, @to_csv )
      end
    end
    
    context "testing add/remove column transformations" do
      context "with simple spreadsheet loaded" do
        setup do
          load_simple_spreadsheet
        end
        
        should "add column" do
          @simple.add_column( :compound ) do |h, record|
            "#{record.fname} #{record.lname} #{record.id}"
          end
          
          load_mary
          assert_equal "Mary Moore 1", @mary.compound
        end
        
        should "drop column" do
          load_mary
          assert @mary.respond_to?(:lname)
          assert_equal "Moore", @mary.lname
          
          @simple.drop_column( :lname )
          
          assert @mary.respond_to?(:age)
          assert_equal "Mary", @mary.fname
          assert_equal false, @mary.respond_to?(:lname)
          assert_equal "27", @mary.age
        end
      end
    end
  end
end
