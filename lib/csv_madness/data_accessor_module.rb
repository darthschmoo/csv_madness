# Each record within the spreadsheet is extended by a module with accessor functions
# which allow the user to treat column names as methods.  When columns are added, dropped, or re-ordered,
# the accessor module needs to be updated to reflect the change.
class DataAccessorModule < Module
  # mapping : keys = column symbol
  #           values = column index
  def initialize( mapping )
    @column_accessors = []
    remap_accessors( mapping )
  end
  
  def install_column_accessors( column, index )
    unless is_valid_ruby_method?( column )
      column = "csv_column_#{index}"
    end
    
    @column_accessors << column
    
    if self.respond_to?( column )
      puts "Column already has accessors"
    else
      eval <<-EOF
          self.send( :define_method, :#{column} ) do
            self.csv_data[#{index}]
          end
      
          self.send( :define_method, :#{column}= ) do |val|
            self.csv_data[#{index}] = val
          end
      EOF
    end
  end
  
  # But if instead of hardcoding the index, the index was pulled from the spreadsheet mapping...
  # a titch slower to look up?  But a change to the mapping automatically updates the method
  def remove_column_accessors( *columns )
    for column in columns.flatten
      self.send( :remove_method, column )
      self.send( :remove_method, :"#{column}=" )
    end
  end
  
  def remove_all_column_accessors
    # 2016-11-24 : was this necessary for anything
    # @column_accessors ||= []
    remove_column_accessors( @column_accessors )
    @column_accessors = []    
  end
  
  def remap_accessors( mapping )
    remove_all_column_accessors
    
    for column, index in mapping
      install_column_accessors( column, index )
    end
  end
  
  # Symbol.inspect doesn't output " quotes when given a sym 
  # that expresses a valid method name or a valid identifier.
  def is_valid_ruby_method?( str_or_sym )
    sym = str_or_sym.to_sym
    test_string = sym.inspect
    
    test_string.match( /^:[@"]/ ).nil?   
  end
end
