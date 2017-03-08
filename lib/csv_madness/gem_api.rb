module CsvMadness
  module GemAPI
    # Loads a sheet from a csv file. If given a relative path, will look in
    # default folders first. 
    def load( csv, opts = {} )
      CsvMadness::Sheet.from( csv, opts )
    end
    
    
    def add_search_path( path )
      CsvMadness::Sheet.add_search_path( path )
    end
    
    # Define a builder using a block, then run
    # the given objects through it to create a
    # Sheet.
    def build( objects, &block )
      CsvMadness::Builder.new(&block).build( objects )
    end
  end
end
