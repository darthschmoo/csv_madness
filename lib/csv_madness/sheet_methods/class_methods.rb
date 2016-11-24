module CsvMadness
  module SheetMethods
    module ClassMethods
      # Used to make getter/setter names out of the original header strings.
      # " hello;: world! " => :hello_world
      def getter_name( name )
        # replace any run of non-word characters with a single "_"
        name = name.downcase.gsub( /(\W|_|\s)+/, "_" )
      
        # snip trailing and leading "_"
        name = name.gsub( /(^_+|_+$)/, "" )
      
        # add leading "_" when we'd otherwise have a method name starting with a digit
        name = "_#{name}" if name.match( /^\d/ )
      
        name.to_sym
      end
    
    
      # Paths to be searched when CsvMadness.load( "filename.csv" ) is called.
      def add_search_path( path )
        @search_paths ||= []
        path = Pathname.new( path ).expand_path
        unless path.directory?
          raise "The given path does not exist"
        end
      
        @search_paths << path unless @search_paths.include?( path )
      end
    
      def search_paths
        @search_paths
      end
    
      def from( csv_file, opts = {} )
        if f = find_spreadsheet_in_filesystem( csv_file )
          Sheet.new( f, opts )
        else
          raise "File not found."
        end
      end
    
      # Search absolute/relative-to-current-dir before checking
      # search paths.
      def find_spreadsheet_in_filesystem( name )
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
      def to_csv( spreadsheet, opts = {} )
        out = spreadsheet.columns.to_csv( opts )
        spreadsheet.records.inject( out ) do |output, record|
          output << record.to_csv( opts )
        end
      end
    
      def write_to_file( spreadsheet, file, opts = {} )
        file = file.fwf_filepath.expand_path
        file.write( spreadsheet.to_csv( opts ) )
      end
    end
  end
end