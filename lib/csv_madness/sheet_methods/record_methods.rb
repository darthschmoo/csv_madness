module CsvMadness
  module SheetMethods
    module RecordMethods
      def add_record( record )
        case record
        when Array
          # CSV::Row.new( column names, column_entries ) (in same order as columns, natch) 
          record = CSV::Row.new( self.columns, record )
        when Hash
          header = []
          fields = []
        
          for col in self.columns
            header << col
            fields << record[col]
          end
        
          record = CSV::Row.new( header, fields )
        when CSV::Row
          # do nothing
        else
          raise "sheet.add_record() doesn't take objects of type #{record.inspect}" unless record.respond_to?(:csv_data)
          record = record.csv_data
        end
      
        record = @record_class.new( record )
        @records << record
        add_to_indexes( record )
      end
    
      alias :<< :add_record
      
      def add_blank_record( &block )
        self.add_record( {} )
        if block_given?
          yield self.records.last
        else
          self.records.last
        end
      end
    
      # record can be the row number (integer from 0...@records.length)
      # record can be the record itself (anonymous class)
      def remove_record( record )
        record = @records[record] if record.is_a?(Integer)
        return if record.nil?
      
        self.remove_from_index( record )
        @records.delete( record )
      end
    
      # Here's the deal: you hand us a block, and we'll remove the records for which
      # it yields _true_.
      def remove_records( records = nil, &block )
        if block_given?
          for record in @records
            remove_record( record ) if yield( record ) == true
          end
        else # records should be an array
          for record in records
            self.remove_record( record )
          end
        end
      end
      
      # Fetches an indexed record based on the column indexed and the keying object.
      # If key is an array of keying objects, returns an array of records in the
      # same order that the keying objects appear.
      # Index column should yield a different, unique value for each record.
      def fetch( index_col, key )
        if key.is_a?(Array)
          key.map{ |k| @indexes[index_col][k] }
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
      # TODO!  Should be returning self rather than the records.a
      def filter!( &block )
        @records = self.filter( &block )
        reindex
        @records
      end
    end
  end
end