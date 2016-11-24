module CsvMadness
  module SheetMethods
    module FileMethods
      def write_to_file( file, opts = {} )
        self.class.write_to_file( self, file, opts )
      end
    
      # pass an arbitrary filepath to save sheet to that filepath
      # call save() with no arguments to overwrite the current spreadsheet file
      # call save(:timestamp) to make a timestamped copy of the spreadsheet file
      #
      # Obviously, the last two require self.spreadsheet_file to exist and be writable
      def save( file = self.spreadsheet_file )
        if file == :timestamp
          if self.spreadsheet_file
            file = self.spreadsheet_file.fwf_filepath.timestamp
          else
            raise ArgumentError.new( "CsvMadness.save(:timestamp) - Spreadsheet must be specified by @spreadsheet_file" )
          end
        end
      
        if file
          self.write_to_file( self.spreadsheet_file, @opts || {} )
        else
          raise "CsvMadness.save(:timestamp) - Spreadsheet must be specified by spreadsheet_file"
        end
      end
      
    
      def reload_spreadsheet( opts = @opts )
        load_csv if @spreadsheet_file
        set_initial_columns( opts[:columns] )
        create_record_class
        package
      
        set_index_columns( opts[:index] )
        reindex
      end
    end
  end
end