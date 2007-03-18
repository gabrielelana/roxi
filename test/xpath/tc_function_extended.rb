require 'roxi'
require 'roxi/xpath'
require 'test/unit'

module ROXI::XPath::Function

  class TestFunctionsExtended < Test::Unit::TestCase
    include ROXI
    include ROXI::XPath

    def test_min
      context = Context.new
      assert_equal 1, Min.eval(context, [1, 2, 3])
      assert_equal 1, Min.eval(context, [1, 2, 3, InfP])
      assert_equal true, Min.eval(context, [1, 2, 3, NaN]).nan?
    end

    def test_max
      context = Context.new
      assert_equal 3, Max.eval(context, [1, 2, 3])
      assert_equal true, Max.eval(context, [1, 2, 3, NaN]).nan?
      assert_equal 1, Max.eval(context, [1, 2, 3, InfP]).infinite?
    end

    def test_avg
      context = Context.new
      assert_equal 0, Avg.eval(context, [])

      nodes = [ XElement.new('node', 5) ]
      assert_equal 5, Avg.eval(context, nodes)

      nodes = [ 
        XElement.new('node', '5'),
        XAttribute.new('name', '10'),
        XText.new('10')
      ]
      assert_equal 25/3.0, Avg.eval(context, nodes)

      assert_equal true, Avg.eval(context, [1, 2, 3, NaN]).nan?
      assert_equal 1, Avg.eval(context, [1, 2, 3, InfP]).infinite?
    end

    def test_mul
      context = Context.new
      assert_equal [2, 4, 6], Mul.eval(context, [1,2,3], [2,2,2])
      assert_equal [2, 4, InfP], Mul.eval(context, [1,2,3], [2,2,InfP])
      assert_equal [2, 4, InfN], Mul.eval(context, [1,2,3], [2,2,InfN])
      assert Mul.eval(context, [1,2,3], [2,2,NaN])[2].nan?
    end

    def test_extension
      context = Context.new

      context.functions['last-arg'] =
        Proc.new do | context, *args |
          args.last
        end
      assert_equal 'foo', ExtensionAdapter.eval(context, 'last-arg', 'a', 'b', 'c', 'foo')

      context.functions['last-arg'] =
        Proc.new do | context, first, last |
          last
        end
      assert_equal 'foo', ExtensionAdapter.eval(context, 'last-arg', 'bar', 'foo')
    end

    def test_sort_in_document_order
      context = Context.new
      root = XDocument.new(
        root = XElement.new('root',
          child_1 = XElement.new('child', 
            child_1_1 = XElement.new('child',
              child_1_1_1 = XElement.new('child'))),
          child_2 = XElement.new('child'),
          attribute_1 = XAttribute.new('name', 'value')
        )
      )
      assert_equal [attribute_1, child_1_1, child_1_1_1, child_2],
        SortInDocumentOrder.eval(context, [child_2, child_1_1_1, attribute_1, child_1_1])
    end

  end

end
