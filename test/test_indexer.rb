require 'helper'

class TestIndexer < MadTestCase
  context "absolute basics" do
    setup do
      @ix = CsvMadness::Indexer.new
    end    
    
    should "have created an Indexer" do
      assert_kind_of CsvMadness::Indexer, @ix
      
      assert_respond_to @ix, :index
      assert_respond_to @ix, :unindex
      assert_respond_to @ix, :lookup
    end
    
    should "add items to and retrieve items from an indexer" do
      @ix.index( 5, :even?, 5.even? )
      result = @ix.lookup( :even?, false )
      assert_equal [5], result
    end
  end 
  
  context "testing index " do
    setup do
      @ix = CsvMadness::Indexer.new
    end
    
    should "add and remove items, with the lookup staying up-to-date" do
      for i in 0..9
        @ix.index( i, :even?, i.even? )
        @ix.index( i, :odd?,  i.odd?  )
      end
      
      assert_equal( [0,2,4,6,8], @ix.lookup( :even?, true  ) )
      assert_equal( [1,3,5,7,9], @ix.lookup( :even?, false ) )
      assert_equal( [0,2,4,6,8], @ix.lookup( :odd?,  false ) )
      assert_equal( [1,3,5,7,9], @ix.lookup( :odd?,  true  ) )
      
      for i in 0..9
        @ix.unindex( i )
      end
      
      assert_equal( [], @ix.lookup( :even?, true  ) )
      assert_equal( [], @ix.lookup( :even?, false ) )
      assert_equal( [], @ix.lookup( :odd?,  true  ) )
      assert_equal( [], @ix.lookup( :odd?,  false ) )
    end
  end
end
