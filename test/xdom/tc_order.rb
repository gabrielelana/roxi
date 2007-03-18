require 'roxi'
require 'test/unit'

module ROXI

  class TestOrder < Test::Unit::TestCase

    def test_element
      root = XElement.new('node')
      assert_equal '1', root.order
    end

    def test_child
      root = XElement.new('node',
        child_first = XElement.new('child'),
        child_second = XElement.new('child'),
        child_last = XElement.new('child')
      )
      assert_equal '1.1', child_first.order
      assert_equal '1.2', child_second.order
      assert_equal '1.3', child_last.order
    end

    def test_root
      doc = XDocument.new(
        root = XElement.new('node')
      )
      assert_equal '1', doc.order
      assert_equal '1.1', root.order
    end

    def test_attribute
      root = XElement.new('node',
        attribute_first = XAttribute.new('first', 'value'),
        attribute_second = XAttribute.new('second', 'value'),
        attribute_last = XAttribute.new('last', 'value'),
        child = XElement.new('child')
      )
      assert_equal '1', root.order
      assert_equal '1.1', child.order
      assert_equal '1%1', attribute_first.order
      assert_equal '1%2', attribute_second.order
      assert_equal '1%3', attribute_last.order
    end

    def test_namespace
      root = XElement.new('node',
        namespace_first = XNamespace.new('first', '/url/first'),
        namespace_second = XNamespace.new('second', '/url/second'),
        namespace_last = XNamespace.new('last', '/url/last'),
        child = XElement.new('child')
      )
      assert_equal '1', root.order
      assert_equal '1.1', child.order
      assert_equal '1#1', namespace_first.order
      assert_equal '1#2', namespace_second.order
      assert_equal '1#3', namespace_last.order
    end

    def test_attribute_and_namespace
      root = XElement.new('node',
        child = XElement.new('child'),
        attribute = XAttribute.new('name', 'value'),
        namespace = XNamespace.new('prefix', '/some/url')
      )
      assert_equal '1.1', child.order 
      assert_equal '1%1', attribute.order 
      assert_equal '1#1', namespace.order

      assert_equal [namespace, attribute, child], [child, attribute, namespace].sort
    end

    def test_misc_elements
      root = XElement.new('root',
        attribute_1 = XAttribute.new('attribute_1', 'value'),
        attribute_2 = XAttribute.new('attribute_2', 'value'),
        child_1 = XElement.new('child',
          attribute_1_1 = XAttribute.new('attribute', 'value'),
          child_1_1 = XElement.new('child',
            attribute_1_1_1 = XAttribute.new('attribute', 'value')
          )
        ),
        child_2 = XElement.new('child'),
        child_3 = XElement.new('child'),
        child_4 = XElement.new('child'),
        child_5 = XElement.new('child')
      )

      assert_equal [attribute_1, child_1_1, attribute_1_1_1, child_2],
        [child_2, child_1_1, attribute_1, attribute_1_1_1].sort
    end

  end

end
