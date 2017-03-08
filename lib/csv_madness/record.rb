module CsvMadness
  # Every Sheet you instantiate will have its very own,
  # anonymous subclass of Record class, which will be 
  # extended by the spreadsheet's own getter/setter module.
  # 
  # @csv_data is currently a CsvRow.  That may change in the
  # future.  I'd like to be able to address by row and by
  # symbol.
  class Record
    include RecordMethods::MethodMethods
    
    attr_accessor :data
    attr_reader   :spreadsheet
    
    def initialize( _data, sheet ) # , mapping )
      @spreadsheet = sheet
      import_record_data( _data )
    end
    
    # Experimental approach to getter/setter methods.  Seems easier than
    # constantly rewriting an accessor module every time the columns get 
    # manipulated.
    #
    # Should raise a method_missing if the get/set method isn't in
    # the index mapping.
    def method_missing( method, *args )
      self.spreadsheet.call_record_method( self, method, args )
    end
    
    
    def [] key
      self.spreadsheet.get_cell( self, key )
    end
    
    
    def []= key, val
      self.spreadsheet.set_cell( self, key, val )
      # case key
      # when String, Integer
      #   @csv_data[key] = val
      # when Symbol
      #   @csv_data[key.to_s] = val
      # end
    end
    
    def columns
      self.spreadsheet.columns
    end
    
    # def self.spreadsheet= sheet
    #   @spreadsheet = sheet
    # end
    #
    # def self.spreadsheet
    #   @spreadsheet
    # end
    #
    def to_csv( opts = {} )
      self.columns.map{|col| self.send(col) }.to_csv( opts )
    end
    
    def to_hash
      self.columns.inject({}){ |hash, col| hash[col] = self.send( col ); hash }
    end
    
    def to_a
      self.data
    end
    
    def blank?( col )
      (self.send( col.to_sym ).to_s || "").strip.length == 0
    end
    
    def inspect
      cols = self.spreadsheet.columns
      cols.zip( self.data ).inspect
    end
    
    
    
    protected
    def import_record_data( _data )
      case _data
      when Array
        self.data = _data
      when Hash
        fields = self.columns.map do |col|
          _data[col]
        end
        # for col in self.columns
        #   fields << data[col]
        # end
        
        self.data = fields # CSV::Row.new( self.columns, fields )
      when CSV::Row
        self.data = _data.to_a.map(&:last)
      when Record
        self.data = _data.data.clone
      else
        raise "Don't know how to handle this input"
      end
    end
  end
end
