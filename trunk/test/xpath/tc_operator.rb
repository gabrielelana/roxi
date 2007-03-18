require 'roxi'
require 'roxi/xpath'
require 'test/unit'

module ROXI::XPath::Operator

  class TestOperator < Test::Unit::TestCase
    include ROXI
    include ROXI::XPath
    
    def test_and
      context = Context.new
      assert_equal true, Operator::And.new(literal(true), literal(true)).eval(context)
      assert_equal false, Operator::And.new(literal(false), literal(false)).eval(context)
    end

    def test_or
      context = Context.new
      assert_equal true, Operator::Or.new(literal(true), literal(true)).eval(context)
      assert_equal false, Operator::Or.new(literal(false), literal(false)).eval(context)
    end

    def test_union
      context = Context.new
      node_1 = XElement.new('node')
      node_2 = XElement.new('node')

      assert_equal [], Operator::Union.new(literal([]), literal([])).eval(context)
      assert_equal [node_1], Operator::Union.new(literal([]), literal([node_1])).eval(context)
      assert_equal [node_1, node_2], Operator::Union.new(literal([node_1]), literal([node_2])).eval(context)
      assert_equal [node_1,node_2], Operator::Union.new(literal([node_1,node_2]), literal([node_1,node_2])).eval(context)
    end

    def test_eq
      context = Context.new
      assert_equal true, Operator::Eq.new(literal(true), literal(true)).eval(context)
    end

    def test_neq
      context = Context.new
      assert_equal false, Operator::Neq.new(literal(true), literal(true)).eval(context)
    end

    def test_lt
      context = Context.new
      assert_equal true, Operator::Lt.new(literal(10), literal(15)).eval(context)
      assert_equal false, Operator::Lt.new(literal(10), literal(10)).eval(context)
    end

    def test_let
      context = Context.new
      assert_equal true, Operator::Let.new(literal(10), literal(15)).eval(context)
      assert_equal true, Operator::Let.new(literal(10), literal(10)).eval(context)
    end

    def test_gt
      context = Context.new
      assert_equal false, Operator::Gt.new(literal(10), literal(15)).eval(context)
      assert_equal false, Operator::Gt.new(literal(10), literal(10)).eval(context)
    end

    def test_get
      context = Context.new
      assert_equal false, Operator::Get.new(literal(10), literal(15)).eval(context)
      assert_equal true, Operator::Get.new(literal(10), literal(10)).eval(context)
    end

    def test_mul
      context = Context.new
      assert_equal 100, Operator::Mul.new(literal(10), literal(10)).eval(context)
    end

    def test_add
      context = Context.new
      assert_equal 20, Operator::Add.new(literal(10), literal(10)).eval(context)
    end

    def test_sub
      context = Context.new
      assert_equal 0, Operator::Sub.new(literal(10), literal(10)).eval(context)
    end

    def test_div
      context = Context.new
      assert_equal 1.4, Operator::Div.new(literal(7.0), literal(5.0)).eval(context)
      assert_equal 1.4, Operator::Div.new(literal(7), literal(5)).eval(context)
      assert_equal InfP, Operator::Div.new(literal(1), literal(0)).eval(context)
      assert_equal InfN, Operator::Div.new(literal(-1), literal(0)).eval(context)
      assert Operator::Div.new(literal(0), literal(0)).eval(context).nan?
    end

    def test_mod
      context = Context.new
      assert_equal 2.0, Operator::Mod.new(literal(7.0), literal(5.0)).eval(context)
      assert_equal 2.0, Operator::Mod.new(literal(7), literal(5)).eval(context)
    end

    def test_neg
      context = Context.new
      assert_equal(-10, Operator::Neg.new(literal(10)).eval(context))
    end

    private

    def literal(value)
      Expression::Literal.new(value)
    end
  end

end
