module CsvMadness
  module SheetMethods
    module ColumnMethods
      COLUMN_TYPES = {
        number: Proc.new do |cell, record|
          rval = cell
        
          unless cell.nil? || (cell.is_a?(String) && cell.length == 0)
        
            begin
              rval = Integer(cell)
            rescue
              # do nothing
            end
        
            unless rval.is_a?(Integer)
              begin
                rval = Float(cell)
              rescue
                # do nothing
              end
            end
          end
        
          rval
        end,
      
        integer: Proc.new do |cell, record|
          begin
            Integer(cell)
          rescue
            cell
          end
        end,
      
        float:   Proc.new do |cell, record|
          begin
            Float(cell)
          rescue
            cell
          end
        end,
      
        date:    Proc.new do |cell, record|
          begin
            parse = Time.parse( cell || "" )
          rescue ArgumentError
            if cell =~ /^Invalid Time Format: /
              parse = cell
            else
              parse = "Invalid Time Format: <#{cell}>"
            end
          end
        
          parse
        end
      }
    
      FORBIDDEN_COLUMN_NAMES = [:to_s]  # breaks things hard when you use them.  Probably not comprehensive, sadly.
      
      
      # can only be called with proper column names (not extra methods)
      def column( col )
        index = index_of_column( col )
      
        # Should be faster...
        @records.map(&:data).map{ |dat| dat[index] }
      end
    
      def has_column?( col )
        self.columns.include?( col.to_sym )
      end
    
      # retrieve multiple columns.  Returns an array of the form
      # [ [record1:col1, record1:col2...], [record2:col1, record2:col2...] [...] ]
      def multiple_columns(*args)
        column_results = args.map do |col| 
          index_of_column( col ) 
        end
        
        column_results.first.zip( *(column_results[1..-1] ) )
      end
      
      def alter_column( col, blank = :undefined, &block )
        cindex = index_of_column( col )

        for record in @records
          if record.blank?( col ) && blank != :undefined
            record[cindex] = blank
          else
            record[cindex] = yield( record[cindex], record )
          end
        end
      end
    
      # If no block given, adds an empty column (blank string).
      # If block given, fills the new column cells when the block is run on each record
      # TODO: Should be able to specify the index of the column
      def add_column( col, &block )
        raise_on_forbidden_column_names( col )
        raise_on_columns_present( col )

        @columns << col
      
        # add empty column to each row
        @records.map{ |r| r.data << "" }
        
        set_column_mapping
        alter_column( col, &block ) if block_given?
      end
    
      
      def drop_column( col )
        index = index_of_column( col )
        @columns.delete( col.to_sym )
      
        @records.map(&:data).map do |dat|
          dat.delete_at( index )
        end
      
        remove_column_from_mapping( col )
      end
    
      def rename_column( old_column_name, new_name )
        raise_on_missing_columns( old_column_name )
        raise_on_forbidden_column_names( new_name )
        
        # - rename the column itself
        # - rename the column in the index
        # - rename the column in the column mapping
        column_index = index_of_column( old_column_name )
        
        @columns[column_index] = new_name
        
        if indexing_enabled? && has_index_column?( old_column_name )
          rename_index_column( column, new_name )
        end
        
        rename_column_mapping_key( old_column_name, new_name )
      end
      
      def set_column_type( column, type, blank = :undefined )
        alter_column( column, blank, &COLUMN_TYPES[type] )
      end

    
      # If :reverse_merge is true, then the dest column is only overwritten for records where :dest is blank
      def merge_columns( source, dest, opts = {} )
        opts = { :drop_source => true, :reverse_merge => false, :default => "" }.merge( opts )
        raise_on_missing_columns( source, dest )
      
        self.records.each do |record|
          if opts[:reverse_merge] == false || record.blank?( dest )
            record[dest] = record.blank?(source) ? opts[:default] : record[source]
          end
        end
      
        self.drop_column( source ) if opts[:drop_source]
      end
    
      # By default, the
      def concat_columns( col1, col2, opts = {} )
        opts =  {:separator => '', :out => col1}.merge( opts )
      
        raise_on_missing_columns( col1, col2 )
        self.add_column( opts[:out] ) unless self.columns.include?( opts[:out] )
      
        for record in self.records
          record[ opts[:out] ] = "#{record[col1]}#{opts[:separator]}#{record[col2]}"
        end
      end
    
      alias :concatenate :concat_columns
      
      def index_of_column( col )
        case col
        when Integer
          col
        when Symbol, String
          raise_on_missing_columns( col )
          @column_mapping[ col.to_sym ]
        end
      end
      
      protected
      def rename_column_mapping_key( old_column_name, new_name )
        @column_mapping[new_name] = @column_mapping.delete( old_column_name )
      end
      
      def remove_column_from_mapping( col )
        index = @column_mapping.delete( col.to_sym )
        
        @column_mapping.each do |_col, i|
          @column_mapping[_col] = i - 1  if i > index
        end
      end
      
      
      
      def raise_on_missing_columns( *cols )
        missing_columns = cols.flatten.reject{ |col| self.has_column?( col ) }
      
        raise MissingColumnError.new( "#{caller[0]}: requested column(s) :#{missing_columns.inspect} not found." ) unless missing_columns.fwf_blank?
      end
      
      def raise_on_columns_present( *cols )
        present_columns = cols.flatten.select{ |col| self.has_column?( col ) }
        
        raise ColumnExistsError.new( "#{caller[0]}: requested column(s) already present: #{present_columns.inspect}" ) unless present_columns.fwf_blank?
      end
    
      def forbidden_column_name?( col )
        FORBIDDEN_COLUMN_NAMES.include?( col )
      end
      
      def raise_on_forbidden_column_names( *cols )
        forbidden_columns = cols.flatten.select{ |col| self.forbidden_column_name?( col ) }
        raise ForbiddenColumnNameError.new( "forbidden names: #{forbidden_columns.inspect}" ) unless forbidden_columns.fwf_blank?
      end
    end
  end
end