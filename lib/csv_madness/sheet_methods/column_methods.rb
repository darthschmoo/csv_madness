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
      
      
      def column col
        @records.map(&col)
      end
    
      def has_column?( col )
        self.columns.include?( col.to_sym )
      end
    
      # retrieve multiple columns.  Returns an array of the form
      # [ [record1:col1, record1:col2...], [record2:col1, record2:col2...] [...] ]
      def multiple_columns(*args)
        @records.inject([]){ |memo, record|
          memo << args.map{ |arg| record.send(arg) }
          memo
        }
      end
      
      def alter_column( column, blank = :undefined, &block )
        raise_on_missing_columns( column )
      
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
    
      # If no block given, adds an empty column.
      # If block given, fills the new column cells when the block is run on each record
      # TODO: Should be able to specify the index of the column
      def add_column( column, &block )
        raise_on_forbidden_column_names( column )
        raise ColumnExistsError.new( "Column already exists: #{column}" ) if @columns.include?( column )

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
        raise_on_missing_columns( column )
      
        @columns.delete( column )
      
        key = column.to_s
      
        @records.map{ |r|
          r.csv_data.delete( key )
        }
      
        update_data_accessor_module
      end
    
      def rename_column( column, new_name )
        @columns[@columns.index(column)] = new_name
        rename_index_column( column, new_name ) if @index_columns.include?( column )
        update_data_accessor_module
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
      
      protected
      def raise_on_missing_columns( *cols )
        missing_columns = cols.flatten.reject{ |col| self.has_column?( col ) }
      
        raise MissingColumnError.new( "#{caller[0]}: required_column(s) :#{missing_columns.inspect} not found." ) unless missing_columns.fwf_blank?
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