module CsvMadness
  module SheetMethods
    module RecordMethods
      def add_record( record, &block )
        case record
        when Array
          # do nothing
        when Hash
          record = @column_mapping.inject( [] ) do |memo, col_and_index|
            col, index = col_and_index
            
            if record.has_key?( col )
              val = record[col]
            elsif record.has_key?( col.to_s )
              val = record[col.to_s]
            else
              val = nil
            end

            if index >= memo.length
              memo.insert( index, val )
            else
              memo[index] = val
            end
            
            memo
          end
        when CSV::Row
          record = record.to_a.map( &:last )
        when CsvMadness::Record
          # TODO: But what if the two records aren't from the same kinds of sheet
          # IOW, different columns or columns in different orders, etc.
          record = record.data
        else
          raise "sheet.add_record() doesn't take objects of type #{record.inspect}" unless record.respond_to?(:csv_data)
          record = record.csv_data
        end
        
        record = Record.new( record, self )
        
        @records << record
        index_records( record ) if indexing_enabled?
        
        record
      end
    
      alias :<< :add_record
      
      def add_blank_record( &block )
        self.add_record( [], &block )
        #
        # if block_given?
        #   yield self.records.last
        # else
        #   self.records.last
        # end
      end
    
      # record can be the row number (integer from 0...@records.length)
      # record can be the record itself
      #
      # returns the record that was removed.  
      def remove_record( record )
        if record.is_a?(Integer)
          record = remove_record_at_index( record )
        else
          record = self.records.delete( record )
        end
        
        self.unindex_record( record ) if indexing_enabled?
        record
      end
      
      def remove_record_at_index( index )
        self.records.delete_at( index )
      end
    
      # Here's the deal: you hand it an array of records (or indexes, or a mix of the two),
      # and it will remove the records (or the index... may want to test the indexing thing).
      # If you give it a block, and it'll remove all the records for which
      # the block yields _true_.
      #
      # returns an array of the removed records, in case you want them for anything.
      def remove_records( records = nil, &block )
        [].tap do |removed|
          if block_given?
            for record in @records
              removed << self.remove_record( record ) if yield( record ) == true
            end
          else # records should be an array
            records = records.map{ |r| r.is_a?( Integer ) ? self[r] : r }   # turn indexes into records
            
            for record in records
              removed << self.remove_record( record )
            end
          end
        end
      end
      
      # Fetches an indexed record based on the column indexed and the keying object.
      # If key is an array of keying objects, returns an array of records in the
      # same order that the keying objects appear.
      # Index column should yield a different, unique value for each record.
      def fetch( index_col, key )
        if indexing_enabled?
          if key.is_a?(Array)
            key.map{ |k| @indexes[index_col][k] }
          else
            @indexes[index_col][key]
          end
        else
          if key.is_a?(Array)
            key.map{ |k| self.fetch( index_col, k ) }
          else
            index = index_of_column( index_col )
            @records.detect{ |r| r.data[index] == key }
          end
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
        reindex if indexing_enabled?
        @records
      end
      
      def extra_method?( m )
        @extra_methods.keys.include?( m )
      end
      
      # The method given should take a record, return... well, anything.
      def add_extra_method( method, &block )
        @extra_methods[method.to_sym] = block
      end
      
      def remove_extra_method( method )
        @extra_methods.delete( method.to_sym )
      end
      
      def call_extra_method( method, record )
        @extra_methods[method.to_sym].call( record )
      end
    end
  end
end