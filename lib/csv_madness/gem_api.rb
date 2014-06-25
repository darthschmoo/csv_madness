module CsvMadness
  module GemAPI
    def load( csv, opts = {} )
      CsvMadness::Sheet.from( csv, opts )
    end
    
    def build( objects, &block )
      builder = CsvMadness::Builder.new(&block)
      builder.build( objects )
    end
  end
end
