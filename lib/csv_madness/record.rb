module CsvMadness
  # Every Sheet you instantiate will have its very own,
  # anonymous subclass of Record class, which will be 
  # extended by the spreadsheet's own getter/setter module.
  # 
  # @csv_data is currently a CsvRow.  That may change in the
  # future.  I'd like to be able to address by row and by
  # symbol.
  class Record
    attr_accessor :csv_data
    attr_reader   :column_accessors_map
    
    def initialize( data, mapping )
      @column_accessors_map = mapping            # holds a reference to its spreadsheet's overall mapping
      import_record_data( data )
    end
    
    def [] key
      case key
      when String, Integer
        @csv_data[key] 
      when Symbol
        @csv_data[key.to_s]
      end
    end
    
    def []= key, val
      case key
      when String, Integer
        @csv_data[key] = val
      when Symbol
        @csv_data[key.to_s] = val
      end
    end
    
    def columns
      self.class.spreadsheet.columns
    end
    
    def self.columns
      self.spreadsheet.columns
    end
    
    def self.spreadsheet= sheet
      @spreadsheet = sheet
    end
    
    def self.spreadsheet
      @spreadsheet
    end
    
    def to_csv( opts = {} )
      self.columns.map{|col| self.send(col) }.to_csv( opts )
    end
    
    def to_hash
      self.columns.inject({}){ |hash, col| hash[col] = self.send( col ); hash }
    end
    
    def to_a
      self.to_hash.to_a
    end
    
    def blank?( col )
      (self.send( col.to_sym ).to_s || "").strip.length == 0
    end
    
    protected
    def import_record_data( data )
      case data
      when Array
        csv_data = CSV::Row.new( self.columns, data )
      when Hash
        fields = self.columns.map do |col|
          data[col]
        end
        # for col in self.columns
        #   fields << data[col]
        # end
        
        csv_data = CSV::Row.new( self.columns, fields )
      when CSV::Row
        csv_data = data
      else
        raise "record.import_record_data() doesn't take objects of type #{data.inspect}" unless data.respond_to?(:csv_data)
        csv_data = data.csv_data.clone
      end
      
      @csv_data = csv_data
    end
  end
end
