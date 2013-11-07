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
    def initialize( data )
      @csv_data = data
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
    
    def self.spreadsheet= sheet
      @spreadsheet = sheet
    end
    
    def self.spreadsheet
      @spreadsheet
    end
    
    def to_csv( opts = {} )
      self.columns.map{|col| self.send(col) }.to_csv( opts )
    end
    
    def blank?( col )
      (self.send( col.to_sym ).to_s || "").strip.length == 0
    end
  end
end
