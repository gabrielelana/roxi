require 'roxi'
require 'test/unit'

include ROXI

class TestNamespace < Test::Unit::TestCase

  def setup
    @root = XElement.new('root',
      @namespace_1 = XNamespace.new('', '/default/namespace'),
      @child_1 = XElement.new('child',
        @attribute_1 = XAttribute.new('attribute', 'value')
      ),
      @child_2 = XElement.new('child',
        @attribute_2 = XAttribute.new('attribute', 'value'),
        @namespace_2 = XNamespace.new('', '/default/namespace/overridden')
      ),
      @child_3 = XElement.new('prefix:child',
        @namespace_3 = XNamespace.new('prefix', '/prefixed/namespace'),
        @attribute_3 = XAttribute.new('attribute', 'value'),
        @attribute_4 = XAttribute.new('prefix:attribute', 'value')
      )
    )
  end

  def test_namespace_element
    assert_equal 1, @root.namespaces.size
    assert_equal '/default/namespace', @root.namespace

    assert_equal '/default/namespace', @child_1.namespace
    assert_equal '/default/namespace/overridden', @child_2.namespace

    assert_equal '/default/namespace', @child_3.namespace('')
    assert_equal '/prefixed/namespace', @child_3.namespace('prefix')
    assert_equal '/prefixed/namespace', @child_3.namespace
  end

  def test_namespace_attribute
    assert_nil @attribute_1.namespace
    assert_nil @attribute_2.namespace
    assert_nil @attribute_3.namespace
    assert_equal '/prefixed/namespace', @attribute_4.namespace
    assert_equal '/prefixed/namespace', @attribute_3.parent.namespace
  end

end
