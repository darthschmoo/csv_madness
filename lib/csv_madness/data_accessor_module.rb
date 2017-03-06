# Each record within the spreadsheet is extended by a module with accessor functions
# which allow the user to treat column names as methods.  When columns are added, dropped, or re-ordered,
# the accessor module needs to be updated to reflect the change.
class DataAccessorModule < Module
  # mapping : keys = column symbol
  #           values = column index
  attr_accessor :column_accessors_map
  
  def initialize( mapping )
    puts "Got mapping #{mapping.inspect}"
    @column_accessors_map = mapping
    remap_accessors
  end
  
  def install_column_accessors( *columns )
    for column in columns.flatten
      unless is_valid_ruby_method?( column )
        warn( "#{column.inspect} is not a valid ruby method" )
        require "data_accessor_module"    # TODO:  WTF?
        column = "csv_column_#{index}"
        warn( "   ----> renaming to #{column.inspect}" )
      end
    
      if self.respond_to?( column )
        puts "Column already has accessors"
      else
        eval <<-EOF
            self.send( :define_method, :#{column} ) do
              self.csv_data[ self.column_accessors_map[ :#{column} ] ]
            end
      
            self.send( :define_method, :#{column}= ) do |val|
              self.csv_data[ self.column_accessors_map[ :#{column} ] ] = val
            end
        EOF
      end
    end
  end
  
  # But if instead of hardcoding the index, the index was pulled from the spreadsheet mapping...
  # a titch slower to look up?  But a change to the mapping automatically updates the method
  def remove_column_accessors( *columns )
    for column in columns.flatten
      for method_sym in [column, :"#{column}="]
        self.send( :remove_method, method_sym ) if self.respond_to?( method_sym )
      end
    end
  end
  
  def remove_all_column_accessors
    # 2016-11-24 : was this necessary for anything
    # @column_accessors ||= []
    remove_column_accessors( @column_accessors_map.keys )
  end
  
  # Partly obsoleted.  
  def remap_accessors( *args )
    # 
    
    
    remove_all_column_accessors
    
    if args.length == 1
      debugger
      @column_accessors_map = args.first
    end
    
    install_column_accessors( @column_accessors_map.keys )
  end
  
  # Symbol.inspect doesn't output " quotes when given a sym 
  # that expresses a valid method name or a valid identifier.
  def is_valid_ruby_method?( str_or_sym )
    sym = str_or_sym.to_sym
    test_string = sym.inspect
    
    test_string.match( /^:[@"]/ ).nil?   
  end
end
