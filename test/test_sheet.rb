require 'helper'

class TestCsvMadness < Test::Unit::TestCase
  context "testing getter_name()" do
    should "return proper function names" do
      assert_equal :hello_world, CsvMadness::Sheet.getter_name( "  heLLo __ world " )
      assert_equal :_0_hello_world, CsvMadness::Sheet.getter_name( "0  heLLo __ worlD!!! " )
    end
  end
end