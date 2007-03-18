require 'roxi'
require 'roxi/xpath'
require 'test/unit'

module ROXI::XPath::Expression

  class TestExpression < Test::Unit::TestCase
    include ROXI::XPath
    include ROXI

    def test_literal
      context = Context.new
      assert_equal 'test', Literal.new('test').eval(context)
      assert_equal 1.0, Literal.new(1.0).eval(context)
    end

    def test_variable
      context = Context.new
      context.variables['var'] = 'test'
      assert_equal 'test', Variable.new('var').eval(context)
      assert_raise(RuntimeError) { Variable.new('fake').eval(context) }
    end

    def test_expression
      context = Context.new
      assert_equal 'foo', Expression.new(Literal.new('foo')).eval(context)
      assert_equal ['foo', 'bar'], Expression.new(Literal.new('foo'), Literal.new('bar')).eval(context)
    end
      
    def test_predicate
      context = Context.new
      assert_equal true, Predicate.new(Literal.new(true)).eval(context)
      assert_equal false, Predicate.new(Literal.new(false)).eval(context)

      context.nodes = [ 'a', 'b', 'c' ]
      context.node = 'a'
      assert_equal true, Predicate.new(Literal.new(1)).eval(context)
      assert_equal false, Predicate.new(Literal.new(2)).eval(context)

      context.node = 'b'
      assert_equal false, Predicate.new(Literal.new(1)).eval(context)
      assert_equal true, Predicate.new(Literal.new(2)).eval(context)
    end

    def test_location_path
      context = Context.new
      root = XElement.new('node',
        XElement.new('child'),
        XElement.new('child')
      )

      context.node = root
      res = RelativeLocationPath.new([
        LocationStep.new(Axis::Child, NodePattern::Node.new)
      ]).eval(context)
      assert_equal 2, res.size

      context.node = root
      res = RelativeLocationPath.new([
        LocationStep.new(
          Axis::Child,
          NodePattern::Node.new,
          [Predicate.new(Literal.new(1))]
        )
      ]).eval(context)
      assert_equal 1, res.size

      context.node = root.children('child').first
      context.document = root
      res = AbsoluteLocationPath.new([
        LocationStep.new(
          Axis::Child,
          NodePattern::Node.new,
          [Predicate.new(Literal.new(1))]
        )
      ]).eval(context)
      assert_equal 1, res.size
    end

    def test_filter_expression
      context = Context.new
      root = XElement.new('node',
        XElement.new('child',
          XElement.new('child'),
          XElement.new('child')
        ),
        XElement.new('child')
      )

      res = Filter.new(
        Literal.new(root.children),
        [Predicate.new(Literal.new(1))]
      ).eval(context)
      assert_equal 1, res.size

      res = Filter.new(
        Literal.new(root.children),
        [ Predicate.new(Literal.new(1)) ],
        RelativeLocationPath.new([
          LocationStep.new(
            Axis::Child,
            NodePattern::Node.new
          )
        ])
      ).eval(context)
      assert_equal 2, res.size

    end

    def test_equality_expression_nodes_vs_nodes
      ns_1 = [ XElement.new('ns_1', 'foo'), XElement.new('ns_1', 'bar') ]
      ns_2 = [ XElement.new('ns_2', 'foo') ]
      ns_3 = [ XElement.new('ns_3', 'bar') ]
      ns_4 = [ XElement.new('ns_4', 'zap') ]

      assert_equal true, eval_equality_rules(:eval_nodes_vs_nodes, ns_1, ns_1, :==)
      assert_equal true, eval_equality_rules(:eval_nodes_vs_nodes, ns_1, ns_2, :==)
      assert_equal true, eval_equality_rules(:eval_nodes_vs_nodes, ns_2, ns_1, :==)
      assert_equal true, eval_equality_rules(:eval_nodes_vs_nodes, ns_1, ns_3, :==)
      assert_equal false, eval_equality_rules(:eval_nodes_vs_nodes, ns_1, ns_4, :==)
      assert_equal false, eval_equality_rules(:eval_nodes_vs_nodes, ns_3, ns_4, :==)
      assert_equal false, eval_equality_rules(:eval_nodes_vs_nodes, [], [], :==)
    end

    def test_equality_expression_nodes_vs_number
      ns_1 = [ XElement.new('ns_1', '1'), XElement.new('ns_1', '2') ]
      ns_2 = [ XAttribute.new('ns_1', 10.5555) ]
      
      assert_equal true, eval_equality_rules(:eval_nodes_vs_number, ns_1, 1.0, :==)
      assert_equal true, eval_equality_rules(:eval_nodes_vs_number, ns_1, 2.0, :==)
      assert_equal false, eval_equality_rules(:eval_nodes_vs_number, ns_1, 3.0, :==)
      assert_equal true, eval_equality_rules(:eval_nodes_vs_number, ns_2, 10.5555, :==)
      assert_equal false, eval_equality_rules(:eval_nodes_vs_number, ns_2, 10.0, :==)
    end

    def test_equality_expression_nodes_vs_string
      ns_1 = [ XElement.new('ns_1', 'foo'), XElement.new('ns_1', 'bar') ]

      assert_equal true, eval_equality_rules(:eval_nodes_vs_string, ns_1, 'foo', :==)
      assert_equal true, eval_equality_rules(:eval_nodes_vs_string, ns_1, 'bar', :==)
      assert_equal false, eval_equality_rules(:eval_nodes_vs_string, ns_1, 'zap', :==)
    end

    def test_equality_expression_nodes_vs_boolean
      ns_1 = [ XElement.new('ns_1', 'foo'), XElement.new('ns_1', 'bar') ]
      ns_2 = []

      assert_equal true, eval_equality_rules(:eval_nodes_vs_boolean, ns_1, true, :==)
      assert_equal true, eval_equality_rules(:eval_nodes_vs_boolean, ns_2, false, :==)
    end

    def test_equality_expression_boolean_vs_value
      assert_equal true, eval_equality_rules(:eval_boolean_vs_value, true, true, :==)
      assert_equal true, eval_equality_rules(:eval_boolean_vs_value, false, false, :==)
      assert_equal true, eval_equality_rules(:eval_boolean_vs_value, 'foo', true, :==)
      assert_equal true, eval_equality_rules(:eval_boolean_vs_value, '', false, :==)
      assert_equal false, eval_equality_rules(:eval_boolean_vs_value, '', true, :==)
      assert_equal true, eval_equality_rules(:eval_boolean_vs_value, 1.0, true, :==)
      assert_equal true, eval_equality_rules(:eval_boolean_vs_value, 0.0, false, :==)
      assert_equal true, eval_equality_rules(:eval_boolean_vs_value, XElement.new('node', 'true'), true, :==)
    end
    
    def test_equality_expression_numeric_vs_value
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, '1', 1.0, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, '0.0', 0, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, '1.0', 1, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, '0', 0.0, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, '10', 10.0, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, '10.0', 10, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, '-10', -10.0, :==)
      assert_equal false, eval_equality_rules(:eval_numeric_vs_value, '1', 0.0, :==)
      assert_equal false, eval_equality_rules(:eval_numeric_vs_value, '1', -1.0, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, true, 1.0, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, false, 0.0, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, XElement.new('node', '1'), 1.0, :==)
      assert_equal true, eval_equality_rules(:eval_numeric_vs_value, XElement.new('node', '1.0'), 1.0, :==)
    end

    def test_equality_expression_string_vs_value
      assert_equal true, eval_equality_rules(:eval_string_vs_value, 'foo', 'foo', :==)
      assert_equal true, eval_equality_rules(:eval_string_vs_value, 'true', true, :==)
      assert_equal true, eval_equality_rules(:eval_string_vs_value, '10', '10', :==)
      assert_equal true, eval_equality_rules(:eval_string_vs_value, '10.0', '10.0', :==)
      assert_equal true, eval_equality_rules(:eval_string_vs_value, XElement.new('node', 'foo'), 'foo', :==)
      assert_equal true, eval_equality_rules(:eval_string_vs_value, XElement.new('node', 'foo'), XElement.new('child', 'foo'), :==)
    end

    def test_relational_expression
      ns_1 = [ XElement.new('ns_1', 20), XElement.new('ns_1', 10) ]
      ns_2 = [ XElement.new('ns_2', 15) ]
    
      assert_equal true, Relational.eval(ns_1, ns_2, :<)
      assert_equal true, Relational.eval(ns_1, 15.0, :<)
      assert_equal true, Relational.eval(ns_1, '11', :<)
      assert_equal true, Relational.eval('10', '11', :<)
      assert_equal false, Relational.eval(ns_1, 10.0, :<)
      assert_equal false, Relational.eval(ns_2, 10.0, :<)
    end

    def test_aritmetic_expression
      ns_1 = [ XElement.new('ns_1', 10), XElement.new('ns_1', 20) ]
      ns_2 = [ XElement.new('ns_2', 15) ]
      attr_1 = XAttribute.new('attribute', '10')
       
      assert_equal 150, Aritmetic.eval(ns_1, ns_2, :*)
      assert_equal 150, Aritmetic.eval(ns_2, ns_1, :*)
      assert_equal 150, Aritmetic.eval(ns_1.first, ns_2.first, :*)
      assert_equal 100, Aritmetic.eval('10', '10', :*)
      assert_equal 100, Aritmetic.eval(10, 10, :*)
      assert_equal 12, Aritmetic.eval(10, '1.2', :*)
      assert_equal 100, Aritmetic.eval(ns_1, 10, :*)
      assert_equal 100, Aritmetic.eval(ns_1, attr_1, :*)
      assert_equal 10, Aritmetic.eval(10, true, :*)
      assert_equal 0, Aritmetic.eval(10, false, :*)
    end


    private

    def eval_equality_rules(message, *args)
      direct_eval = catch(:done) do
        Equality.send(message, *args)
      end
      rules_eval = Equality.eval(*args)
      assert_equal direct_eval, rules_eval
      rules_eval
    end

  end

end
