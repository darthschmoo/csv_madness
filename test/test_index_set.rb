require 'helper'

class TestIndexSet < MadTestCase
  include CsvMadness
  
  context "testing set equality" do
    setup do
      @set0 = IndexSet.new( :even, true )
      @set1 = IndexSet.new( :odd, false )
    end    
    
    should "be unequal when empty" do
      @set0 != @set1
    end
    
    should "be unequal when containing the same objects" do
      @set0.add( 0 )
      @set1.add( 0 )
      
      @set0 != @set1
    end
    
    should "do a thing" do
      1000.times do
        ix = IndexSet.new( :even, :true )
        puts ix.object_id
      end
    end
  end
end
