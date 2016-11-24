module CsvMadness
  module SheetMethods
    module Indexing
      def set_index_columns( index_columns )
        @index_columns = case index_columns
        when NilClass
          []
        when Symbol
          [ index_columns ]
        when Array
          index_columns
        end
      end
      
      def add_to_index( col, key, record )
        (@indexes[col] ||= {})[key] = record
      end
    
      def add_to_indexes( records )
        if records.is_a?( Array )
          for record in records
            add_to_indexes( record )
          end
        else
          record = records
          for col in @index_columns
            add_to_index( col, record.send(col), record )
          end
        end
      end
    
      def remove_from_index( record )
        for col in @index_columns
          @indexes[col].delete( record.send(col) )
        end
      end
    
      # Reindexes the record lookup tables.
      def reindex
        @indexes = {}
        add_to_indexes( @records )
      end
    
      # shouldn't require reindex
      def rename_index_column( column, new_name )
        @index_columns[ @index_columns.index( column ) ] = new_name
        @indexes[new_name] = @indexes[column]
        @indexes.delete(column)
      end
    end
  end
end