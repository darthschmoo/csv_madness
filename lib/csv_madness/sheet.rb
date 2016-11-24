module CsvMadness
  class Sheet
    extend  SheetMethods::ClassMethods 
    include SheetMethods::Base
    include SheetMethods::Indexing
    include SheetMethods::FileMethods
    include SheetMethods::ColumnMethods
    include SheetMethods::RecordMethods
    
    
    attr_reader :columns, :index_columns, :records, :record_class, :opts
    attr_accessor :spreadsheet_file
    
    # opts: 
    #   index: ( [:id, :id2 ] )
    #       columns you want mapped for quick 
    #       lookup of individual records
    #
    #   columns: ( [:fname, :lname, :age] )  
    #       an array of symbols, corresponding
    #       to the csv rows they represent (first, second, third)
    #       and designating the method for calling the cell in 
    #       a given record.  If not provided, it will guess based
    #       on the header row.
    #   
    #   header:   false       
    #       anything else, we assume the csv file has a header row
    def initialize( *args )
      @csv = nil
      
      if args.last.is_a?(Hash)
        @opts = args.pop
      else
        @opts = {}
      end
      
      firstarg = args.shift
      
      case firstarg
      when NilClass
        @spreadsheet_file = nil
        @opts[:columns] ||= []
      when String, FunWith::Files::FilePath, Pathname
        @spreadsheet_file = self.class.find_spreadsheet_in_filesystem( firstarg )
      when Array
        @spreadsheet_file = nil
        @opts[:columns] ||= firstarg
      end
      
      @opts[:header] = (@opts[:header] == false ? false : true)  # true unless already explicitly set to false
      
      reload_spreadsheet
    end
    
    

    def to_csv( opts = {} )
      self.records.inject( self.columns.to_csv( opts ) ) do |output, record|
        output << record.to_csv( opts )
      end
    end

    def [] offset
      @records[offset]
    end
  
    
    # give a copy of the current spreadsheet, but with no records
    def blanked()
      sheet = self.class.new
      sheet.columns = @columns.clone
      sheet.index_columns = @index_columns.clone
      sheet.records = []
      sheet.spreadsheet_file = nil
      sheet.create_data_accessor_module
      sheet.create_record_class
      sheet.opts = @opts.clone
      sheet.reindex
      
      sheet
    end
    
    # give a block, and get back a hash.  
    # The hash keys are the results of the block.
    # The hash values are copies of the spreadsheets, with only the records
    # which caused the block to return the key.
    def split( &block )
      sheets = Hash.new
      
      for record in @records
        result_key = yield record
        ( sheets[result_key] ||= self.blanked() ) << record
      end

      sheets
      # sheet_args = self.blanked
      # for key, record_set in records
      #   sheet = self.clone
      #   sheet.records = 
      #   
      #   records[key] = sheet
      # end
      # 
      # records
    end
    
    
    # if blank is defined, only the records which are non-blank in that
    # column will actually be yielded.  The rest will be set to the provided
    # default
    def alter_cells( blank = :undefined, &block )
      @columns.each_with_index do |column, cindex|
        alter_column( column, blank, &block )
      end
    end

    
    # Note: If a block is given, the mod arg will be ignored.
    def add_record_methods( mod = nil, &block )
      if block_given?
        mod = Module.new( &block )
      end
      @record_class.send( :include, mod )
      self
    end
    
    # Note: If implementation of Record[] changes, so must this.
    def nils_are_blank_strings
      alter_cells do |value, record|
        value.nil? ? "" : value
      end
    end
    
    def length
      self.records.length
    end
    
    protected
    attr_writer :columns, :index_columns, :records, :record_class, :opts    
    
    def load_csv
      
      # encoding seems to solve a specific problem with a specific spreadsheet, at an unknown cost.
      @csv = CSV.new( File.read(@spreadsheet_file).force_encoding("ISO-8859-1").encode("UTF-8"), 
                        { write_headers: true, 
                          headers: ( @opts[:header] ? :first_row : false ) } )
    end
    
    # Each spreadsheet has its own anonymous record class, and each CSV row instantiates
    # a record of this class.  This is where the getters and setters come from.
    def create_record_class
      create_data_accessor_module
      @record_class = Class.new( CsvMadness::Record )
      @record_class.spreadsheet = self
      @record_class.send( :include, @module )
    end
    
    # fetch the original headers from the CSV file.  If opts[:headers] is false,
    # or the CSV file isn't loaded yet, returns an empty array.
    def fetch_csv_headers
      if @csv && @opts[:header]
        if @csv.headers == true
          @csv.shift
          headers = @csv.headers
          @csv.rewind   # shift/rewind, else @csv.headers only returns 'true'
        else
          headers = @csv.headers
        end
        headers
      else
        []
      end
    end
    
    # sets the list of columns. 
    # If passed nil:
    #   if the CSV file has headers, will try to create column names based on headers.
    #   otherwise, you end up with accessors like record.col1, record.col2, record.col3...
    # If the columns given doesn't match the number of columns in the spreadsheet 
    # prints a warning and a comparison of the columns to the headers.
    def set_initial_columns( columns = nil )
      if columns.nil?
        if @opts[:header] == false
          columns = (0...csv_column_count).map{ |i| :"col#{i}" }
        else
          columns = fetch_csv_headers.map{ |name| self.class.getter_name( name ) }
        end
      else
        unless !@csv || columns.length == csv_column_count
          $stderr.puts "Warning <#{@spreadsheet_file}>: columns array does not match the number of columns in the spreadsheet." 
          @columns = columns
          compare_columns_to_headers
        end
      end

      raise_on_forbidden_column_names( columns )

      @columns = columns
    end
    
    # Printout so the user can see which CSV columns are being matched to which
    # getter/setters.  Helpful for debugging dropped or duplicate entries in the
    # column list.
    def compare_columns_to_headers
      headers = fetch_csv_headers
      max_index = ([@columns, headers].map(&:length).max)
      
      for i in 0 ... max_index
        $stdout.puts "\t#{i}:  #{@columns[i].inspect} ==> #{headers[i].inspect}"
      end
    end
    
    
    # Create objects that respond to the recipe-named methods
    def package
      @records = []
      (@csv || []).each do |row|
        @records << @record_class.new( row )
      end
    end
  
    # How many columns?  Based off the length of the headers.
    def csv_column_count
      fetch_csv_headers.length
    end
    
    def columns_to_mapping
      @columns.each_with_index.inject({}){ |memo, item| 
        memo[item.first] = item.last
        memo 
      }
    end
  
    def create_data_accessor_module
      # columns = @columns                 # yes, this line is necessary. Module.new has its own @vars.
      
      @module = DataAccessorModule.new( columns_to_mapping )
    end
    
    def update_data_accessor_module
      @module.remap_accessors( columns_to_mapping )
    end
  end
end