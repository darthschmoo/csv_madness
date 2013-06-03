class DataAccessorModule < Module
  def initialize( mapping )
    @column_accessors = []
    remap_accessors( mapping )
  end
  
  def install_column_accessors( column, index )
    @column_accessors << column
    eval <<-EOF
      self.send( :define_method, :#{column} ) do
        self.csv_data[#{index}]
      end
      
      self.send( :define_method, :#{column}= ) do |val|
        self.csv_data[#{index}] = val
      end
    EOF
  end
  
  def remove_column_accessors( column )
    self.send( :remove_method, column )
    self.send( :remove_method, :"#{column}=" )
  end
  
  def remove_all_column_accessors
    @column_accessors ||= []    
    
    for sym in @column_accessors
      remove_column_accessors( sym )
    end
    
    @column_accessors = []    
  end
  
  def remap_accessors( mapping )
    remove_all_column_accessors
    
    @mapping = mapping
    
    for column, index in @mapping
      install_column_accessors( column, index )
    end
  end
end
