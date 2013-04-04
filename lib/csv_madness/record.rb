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
      @csv_data[key]
    end
    
    def []= key, val
      @csv_data[key] = val
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
  end
end
