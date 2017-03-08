module CsvMadness
  class Indexer
    # This could be a general-purpose module.  So I'm dropping the restriction
    # that the index has to be keyed to a symbol.  Should be simple enough to
    # manage on the caller's end, if that's needed
    def initialize
      # Maintaining this information is necessary to remove items
      # from the indexes quickly.
      @sets_containing_the_item = {}   # key: a item, value: a set of set sets which live in @indexes
      @indexes = {}
    end


    # If the item has previously been indexed in this index_name under another
    # value, it must be removed
    def index( item, index_key, index_val )
      @sets_containing_the_item[item] ||= Set.new

      @indexes[index_key] ||= {}
      @indexes[index_key][index_val] ||= IndexSet.new( index_key, index_val )

      unindex_item_from_one_index( item, index_key )

      added_set = @indexes[index_key][index_val]
      added_set.add( item )
      
      @sets_containing_the_item[item].add( added_set )

      item
    end

    # remove the item from all
    def unindex( item )
      if @sets_containing_the_item.has_key?( item )
        for item_set in @sets_containing_the_item[item]
          item_set.delete( item )
        end

        @sets_containing_the_item.delete( item )
      end

      item
    end

    def unindex_item_from_one_index( item, index_key )
      indx = @indexes[index_key]

      unless indx.fwf_blank?

      end
    end

    # returns an array of items whose index_val matches the given value
    def lookup( index_key, index_val )
      if @indexes.has_key?( index_key ) && @indexes[index_key].has_key?( index_val )
        @indexes[index_key][index_val].to_a
      else
        []
      end
    end

    # worrying cases:
    #
    # If the old index_name name doesn't exist and new index_name name doesn't exist,
    # it's a null operation
    #
    # If the new_index_name already exists, will raise an error rather than
    # accidentally discarding the index.
    def rename_index( old_index_key, new_index_key )
      raise IndexExistsError.new( "Index exists: #{new_index_key}" ) if @indexes.has_key?( new_index_key )

      @indexes[new_index_key] = @indexes.delete( old_index_key )
    end

    # deletes all indexing information for the given index
    def drop_index( index_key )
      # returns
      sets_to_remove = @indexes.delete( index_key )

      unless set_to_remove.fwf_blank?
        # ci => key => a set of items
        @sets_containing_the_item.each do |item, set|
          set.delete( set_to_remove )
        end
      end
    end
  end
end