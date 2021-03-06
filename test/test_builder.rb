require 'helper'

class TestBuilder < MadTestCase
  context "testing simple cases" do
    should "spreadsheetize integers" do
      integers = [65, 66, 67, 68, 69, 70]
      sb = CsvMadness::Builder.new do |s|
        s.column( :even, "even?" )
        s.column( :odd, "odd?" )
        s.column( :hashh, "hash" )
        s.column( :hashhash, "hash.hash" )
        s.column( :chr )
        s.column( :not_a_valid_method )
      end
      # 
      ss = sb.build( integers )
      
      for record in ss.records
        assert_kind_of( CsvMadness::Record, ss.records.first )
        for col in [:even, :odd, :hashh, :hashhash, :chr]
          assert_respond_to record, col
        end
      end
      
      assert_matches ss.records.first.not_a_valid_method, /^ERROR: undefined method `not_a_valid_method'/
      
      ss = sb.build( integers, :on_error => :ignore )
      
      assert_equal "", ss.records.first.not_a_valid_method
      
    end
  end
end