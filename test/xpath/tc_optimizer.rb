require 'roxi/xpath'
require 'test/unit'

module ROXI::XPath

  class TestOptimizer < Test::Unit::TestCase
    
    def test_simple
      assert_equal '', Optimizer.optimize('')
      assert_equal '/descendant-or-self::node()', Optimizer.optimize('//')
      assert_equal 'count(/descendant-or-self::node())', Optimizer.optimize('count(//)')
      assert_equal '/descendant-or-self::*', Optimizer.optimize('//*')
      assert_equal '/descendant-or-self::child', Optimizer.optimize('//child')
      assert_equal '/descendant-or-self::child-child', Optimizer.optimize('//child-child')
      assert_equal '/descendant-or-self::node()', Optimizer.optimize('//node()')
      assert_equal '/descendant-or-self::processing-instruction()', Optimizer.optimize('//processing-instruction()')
      assert_equal '/descendant-or-self::prefix:name', Optimizer.optimize('//prefix:name')
      assert_equal '/descendant-or-self::child[1]', Optimizer.optimize('//child[1]')
      assert_equal '/descendant-or-self::child[/descendant-or-self::node()]', Optimizer.optimize('//child[//]')
      assert_equal '/descendant-or-self::child | /descendant-or-self::child', Optimizer.optimize('//child | //child')
    end

  end

end
