module CsvMadness
  class Sheet
    extend  SheetMethods::ClassMethods 
    include SheetMethods::Base
    # include SheetMethods::Indexing    # TODO: May never re-implement
    include SheetMethods::FileMethods
    include SheetMethods::ColumnMethods
    include SheetMethods::RecordMethods
    
    def indexing_enabled?
      false
    end
    
    attr_reader :columns, :column_mapping, :opts, :extra_methods
    attr_accessor :spreadsheet_file
    
    # new( <optional non-hash first argument>, <optional hash of options> )
    # firstarg:
    #   nil or no first argument given: this Spreadsheet object isn't associated with a .csv file
    #
    #  string or path: create Spreadsheet by reading contents of a CSV file
    #  
    #  array: sets the columns.  Overlaps with opts[:columns], and should likely be removed.
    #    
    #   
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
      @extra_methods = {}  # key = method name as symbol, val: a proc that takes a record as an argument, and possibly a block
      
      if indexing_enabled?
        @index_columns = []
        @indexes = {}
      end
      
      if args.last.is_a?(Hash)
        @opts = args.pop
      else
        @opts = {}
      end
      
      firstarg = args.shift
      
      case firstarg
      when NilClass               # Blank sheet, no affiliation with an existing csv file
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
    
    
    def call_record_method( record, method, args )
      if extra_method?( method )
        # call the decorated method
        call_extra_method( method, record, *args )
      else
        if method[-1] == '='
          key = method[0..-2]
          set_cell( record, key, args.first )
        else
          get_cell( record, method )
        end
      end
    end
  
    def get_cell( record, key )
      record = self[record] if record.is_a?( Integer )  

      index = if key.is_a?( Integer )
                key
              elsif has_column?( key )
                index_of_column( key )
              else
                raise NoMethodError.new( "Column does not exist: #{key}" )
              end
      
      record.data[ index ]
    end
  
  
    # TODO:  Also update the index if necessary
    def set_cell( record, key, val )
      record = self[record] if record.is_a?( Integer )  

      record.data[ index_of_column( key ) ] = val
    end
    
    
    
    
    

    def to_csv( opts = {} )
      self.records.inject( self.columns.to_csv( opts ) ) do |output, record|
        output << record.to_csv( opts )
      end
    end

    def [] offset
      @records[offset]
    end
    
    def records
      @records ||= []
    end
  
    
    # give a copy of the current spreadsheet, but with no records
    def blanked()
      sheet = self.class.new
      sheet.columns = @columns.clone
      
      
      sheet.index_columns = @index_columns.clone   if indexing_enabled?
      
      sheet.records = []
      sheet.spreadsheet_file = nil
      # sheet.create_data_accessor_module
      # sheet.create_record_class
      sheet.opts = @opts.clone
      sheet.reindex if indexing_enabled?
      
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
    attr_writer :columns, :records, :record_class, :opts    
    
    def load_csv
      
      # encoding seems to solve a specific problem with a specific spreadsheet, at an unknown cost.
      @csv = CSV.new( File.read(@spreadsheet_file).force_encoding("ISO-8859-1").encode("UTF-8"), 
                        { write_headers: true, 
                          headers: ( @opts[:header] ? :first_row : false ) } )
    end

    # No longer needed.
    # # Each spreadsheet has its own anonymous record class, and each CSV row instantiates
    # # a record of this class.  This is where the getters and setters come from.
    # def create_record_class
    #   create_data_accessor_module
    #   @record_class = Class.new( CsvMadness::Record )
    #   @record_class.spreadsheet = self
    #   @record_class.send( :include, @module )
    # end
    
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
    def set_columns( columns = nil )
      if columns.nil?
        if @opts[:header] == false
          columns = (0...csv_column_count).map{ |i| self.class.default_column_name(i) }
        else
          header_list = fetch_csv_headers
          columns = header_list.each_with_index.map do |name, index|
            self.class.getter_name( name || self.class.default_column_name( index ) )
          end
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
      set_column_mapping
    end
    
    def set_column_mapping
      @column_mapping = @columns.each_with_index.inject( {} ) do |memo, col_with_index|
        memo[col_with_index.first.to_sym] = col_with_index.last
        memo
      end
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
    def package_each_csv_row
      @records = []
      (@csv || []).each do |row|
        @records << Record.new( row, self )
      end
    end
  
    # How many columns?  Based off the length of the headers.
    def csv_column_count
      fetch_csv_headers.length
    end
    
    # # returns a mapping based off the current ordered list of columns.
    # # A hash where the first column
    # def columns_to_mapping
    #   @columns.each_with_index.inject({}){ |memo, item|
    #     memo[item.first] = item.last
    #     memo
    #   }
    # end
    #
    # def create_data_accessor_module
    #   # columns = @columns                 # yes, this line is necessary. Module.new has its own @vars.
    #
    #   @module = DataAccessorModule.new( columns_to_mapping )
    # end
    #
    # def update_data_accessor_module
    #   debugger
    #   @module.remap_accessors( columns_to_mapping )
    # end
    #
    # def column_accessors_map
    #   @module.column_accessors_map
    # end
  end
end