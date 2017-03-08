module CsvMadness
  module SheetMethods
    module Indexing
      attr_accessor :index_columns
      
      def set_index_columns( index_columns )
        cols =  case index_columns
                when NilClass
                  []
                when Symbol
                  [ index_columns ]
                when Array
                  index_columns.map{|col| add_index_column( col ) }
                end
        for col in cols.map(&:to_sym)
          remove_index_column( col ) if self.has_index_column?( col )
          add_index_column( col )
        end
      end
      
      def add_index_column( col )
        raise_if_index_columns( col )
        
        col = col.to_sym
        
        @index_columns << col
        @indexes[col] = {}
        
        reindex( col )
      end
      
      # TODO:  Suddenly seeing a huge problem with the indexes.  
      #        What if the index values aren't unique?
      # Add a single record to a single index. Index value calculated by caller.
      def add_to_index( col, index_value, record )
        raise_unless_index_columns( col )
        
        remove_from_index( col, record )   # first remove in case it's been indexed previously with a different value... gah, this is getting ugly.
        
        index_hash = (@indexes[col.to_sym] ||= {})
        index_hash_records = (index_hash[index_value] ||= Set.new)
        
        index_hash_records << record
      end
      
      def unindex_record( record )
        for index_col in @index_columns
          remove_from_index( index_col, record )
        end
      end
      
      def remove_from_index( col, record )
        raise_unless_index_columns( col )
        
        @indexes[col.to_sym].each do |index_value, indexed_records| 
          indexed_records.delete( record )
        end
      end
      
      
      
    
      def index_records( records )
        if records.is_a?( Array )
          for record in records
            index_records( record )
          end
        else
          record = records
          for col in @index_columns
            add_to_index( col, record.send(col), record )
          end
        end
      end

      def has_index_column?( col )
        @index_columns.include?( col.to_sym )
      end
    
      # Reindexes the record lookup tables.
      def reindex( *cols  )
        # for column in (columns )
        #
        # @indexes = {}
        # index_records( @records )
      end
      
      def empty_indexes( *cols )
        raise_unless_index_columns( cols )
        
        icols = @index_columns if cols.fwf_blank?
        
        for icol in icols
          @indexes[icol.to_sym] = {}
        end
      end  
    
      # shouldn't require reindex
      def rename_index_column( old_name, new_name )
        @index_columns[ @index_columns.index( old_name ) ] = new_name
        @indexes[new_name] = @indexes.delete( old_name )  
      end
      
      def remove_index_column( column_name )
        raise_unless_index_columns( column_name )
        
        @indexes.delete( column_name.sym )
        @index_columns.delete( column_name.sym )
      end
      
      protected
      # def each_index_column( cols = @index_columns, &block )
      #   raise_unless_index_columns( cols )
      #
      #   for col in cols
      #     yield col.to_sym
      #   end
      # end
      
      def raise_unless_index_columns( *cols )
        absent_columns = cols.reject{ |col| self.has_index_column?( col ) }
        
        raise MissingColumnError.new( "Not an index column(s): #{absent_columns.inspect}" ) unless absent_columns.fwf_blank?
      end

      def raise_if_index_columns( *cols )
        present_columns = cols.detect{ |col| self.has_index_column?( col ) }
        
        raise MissingColumnError.new( "Index column(s) already exist: #{present_columns.inspect}" ) unless present_columns.fwf_blank?
      end
    end
  end
end