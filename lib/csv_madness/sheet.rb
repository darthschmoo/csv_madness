module CsvMadness
  class Sheet
    COLUMN_TYPES = {
      number: Proc.new do |cell, record|
        if (cell || "").strip.match(/^\d*$/)
          cell.to_i
        else
          cell.to_f
        end
      end,
      
      integer: Proc.new do |cell, record|
        cell.to_i
      end,
      
      float:   Proc.new do |cell, record|
        cell.to_f
      end,
      
      date:    Proc.new do |cell, record|
        begin
          parse = Time.parse( cell )
        rescue ArgumentError
          parse = "Invalid Time Format: <#{cell}>"
        end
        parse
      end
    }
    
    # Used to make getter/setter names out of the original header strings.
    # " hello;: world! " => :hello_world
    def self.getter_name( name )
      name = name.strip.gsub(/\s+/,"_").gsub(/(\W|_)+/, "" ).downcase
      if name.match( /^\d/ )
        name = "_#{name}"
      end
      
      name.to_sym
    end
    
    
    # Paths to be searched when CsvMadness.load( "filename.csv" ) is called.
    def self.add_search_path( path )
      @search_paths ||= []
      path = Pathname.new( path ).expand_path
      @search_paths << path unless @search_paths.include?( path )
    end
    
    def self.from( csv_file, opts = {} )
      if f = find_spreadsheet_in_filesystem( csv_file )
        Sheet.new( f, opts )
      else
        raise "File not found."
      end
    end
    
    # Search absolute/relative-to-current-dir before checking
    # search paths.
    def self.find_spreadsheet_in_filesystem( name )
      @search_paths ||= []

      expanded_path = Pathname.new( name ).expand_path
      if expanded_path.exist?
        return expanded_path
      else   # look for it in the search paths
        @search_paths.each do |p|
          file = p.join( name )
          if file.exist? && file.file?
            return p.join( name )
          end
        end
      end
      
      nil
    end
    
    # opts are passed to underlying CSV (:row_sep, :encoding, :force_quotes)
    def self.to_csv( spreadsheet, opts = {} )
      out = spreadsheet.columns.to_csv( opts )
      spreadsheet.records.inject( out ) do |output, record|
        output << record.to_csv( opts )
      end
    end
    
    def self.write_to_file( spreadsheet, file, opts = {} )
      file = Pathname.new(file).expand_path
      File.open( file, "w" ) do |f|
        f << spreadsheet.to_csv( opts )
      end
    end
    
    def write_to_file( file, opts = {} )
      self.class.write_to_file( self, file, opts )
    end

    def to_csv( opts = {} )
      self.records.inject( self.columns.to_csv( opts ) ) do |output, record|
        output << record.to_csv( opts )
      end
    end
    
    attr_reader :columns, :records, :spreadsheet_file, :record_class
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
    def initialize( spreadsheet, opts = {} )
      @spreadsheet_file = self.class.find_spreadsheet_in_filesystem( spreadsheet )
      @opts = opts
      @opts[:header] = (@opts[:header] == false ? false : true)  # true unless already explicitly set to false
      
      load_csv
      
      set_initial_columns( @opts[:columns] )
      

      create_record_class
      package
      
      @index_columns = case @opts[:index]
      when NilClass
        []
      when Symbol
        [ @opts[:index] ]
      when Array
        @opts[:index]
      end
        
      reindex
    end
    
    def [] offset
      @records[offset]
    end
  
    # Fetches an indexed record based on the column indexed and the keying object.
    # If key is an array of keying objects, returns an array of records in the
    # same order that the keying objects appear.
    # Index column should yield a different, unique value for each record.
    def fetch( index_col, key )
      if key.is_a?(Array)
        key.map{ |key| @indexes[index_col][key] }
      else
        @indexes[index_col][key]
      end
    end
    
    # function should take an object, and return either true or false
    # returns an array of objects that respond true when put through the
    # meat grinder
    def filter( &block )
      rval = []
      @records.each do |record|
        rval << record if ( yield record )
      end
    
      rval
    end
    
    # removes rows which fail the given test from the spreadsheet.
    def filter!( &block )
      @records = self.filter( &block )
      reindex
      @records
    end
  
    def column col
      @records.map(&col)
    end
    
    # retrieve multiple columns.  Returns an array of the form
    # [ [record1:col1, record1:col2...], [record2:col1, record2:col2...] [...] ]
    def multiple_columns(*args)
      @records.inject([]){ |memo, record|
        memo << args.map{ |arg| record.send(arg) }
        memo
      }
    end
    
    # if blank is defined, only the records which are non-blank in that
    # column will actually be yielded.  The rest will be set to the provided
    # default
    def alter_cells( blank = :undefined, &block )
      @columns.each_with_index do |column, cindex|
        alter_column( column, blank, &block )
      end
    end

    # if column doesn't exist, silently fails.  Proper behavior?  Dunno.
    def alter_column( column, blank = :undefined, &block )
      if cindex = @columns.index( column )
        for record in @records
          if record.blank?(column) && blank != :undefined
            record[cindex] = blank
          else
            record[cindex] = yield( record[cindex], record )
          end
        end
      end
    end
    
    def add_column( column, &block )
      raise "Column already exists" if @columns.include?( column )
      @columns << column
      
      # add empty column to each row
      @records.map{ |r|
        r.csv_data << {column => ""} 
      }
      
      update_data_accessor_module
      
      if block_given?
        alter_column( column ) do |val, record|
          yield val, record
        end
      end
    end
    
    def drop_column( column )
      raise "Column does not exist" unless @columns.include?( column )
      
      @columns.delete( column )
      
      key = column.to_s
      
      @records.map{ |r|
        r.csv_data.delete( key )
      }
      
      update_data_accessor_module
    end
    
    def set_column_type( column, type, blank = :undefined )
      alter_column( column, blank, &COLUMN_TYPES[type] )
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
    
    protected
    def load_csv
      # encoding seems to solve a specific problem with a specific spreadsheet, at an unknown cost.
      @csv = CSV.new( File.read(@spreadsheet_file).force_encoding("ISO-8859-1").encode("UTF-8"), 
                        { write_headers: true, 
                          headers: ( @opts[:header] ? :first_row : false ) } )
    end
      
    def add_to_index( col, key, record )
      @indexes[col][key] = record
    end
    
    # Reindexes the record lookup tables.
    def reindex
      @indexes = {}
      for col in @index_columns
        @indexes[col] = {}

        for record in @records
          add_to_index( col, record.send(col), record )
        end
      end
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
        if @opts[:header] == false    #
          @columns = (0...csv_column_count).map{ |i| :"col#{i}" }
        else
          @columns = fetch_csv_headers.map{ |name| self.class.getter_name( name ) }
        end
      else
        @columns = columns
        unless @columns.length == csv_column_count
          puts "Warning <#{@spreadsheet_file}>: columns array does not match the number of columns in the spreadsheet." 
          compare_columns_to_headers
        end
      end
    end
    
    # Printout so the user can see which CSV columns are being matched to which
    # getter/setters.  Helpful for debugging dropped or duplicate entries in the
    # column list.
    def compare_columns_to_headers
      headers = fetch_csv_headers

      for i in 0...([@columns, headers].map(&:length).max)
        puts "\t#{i}:  #{@columns[i]} ==> #{headers[i]}"
      end
    end
    
    
    # Create objects that respond to the recipe-named methods
    def package
      @records = []
      @csv.each do |row|
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