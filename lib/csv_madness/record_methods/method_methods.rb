module CsvMadness
  module RecordMethods
    module MethodMethods
      alias :respond_to_naturally? :respond_to?
      alias :natural_methods :methods
      
      def extra_method?( method )
        self.spreadsheet.extra_methods.keys.include?( method )
      end
      
      def column_method?( method )
        column_setter_method?( method ) || column_getter_method?( method )
      end
      
      def column_setter_method?( method )
        if method[-1] == "="
          self.spreadsheet.has_column?( method[0..-2].to_sym )
        else
          false
        end
      end
      
      def column_getter_method?( method )
        self.spreadsheet.has_column?( method )
      end
  
      def respond_to?( method )
        self.methods.include?( method )
      end
      
      def methods
        self.natural_methods + 
          self.spreadsheet.extra_methods.keys + 
          self.spreadsheet.columns +
          self.spreadsheet.columns.map{ |col| to_setter_method( col ) }
      end
      
      def to_setter_method( method )
        if method[-1] != "="
          "#{method}=".to_sym
        else
          method.to_sym
        end
      end
      
      def to_getter_method( method )
        if method[-1] == "="
          method[0..-2].to_sym
        else
          method.to_sym
        end
      end
    end
  end
end
  
      