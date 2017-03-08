module CsvMadness
  # Used by indexer to store indexing data.  With a regular set, two sets 
  # are considered equal if they hold the same objects, which is a problem
  # for the @sets_containing_item data (needed for unindexing)
  class IndexSet < Set
    attr_reader :index_key, :index_value
    
    def initialize( k, v )
      super()
      @index_key = k
      @index_value = v
    end
  end
end