require 'roxi'
require 'test/unit'

include ROXI

class TestEach < Test::Unit::TestCase

  def setup
    @root = XElement.new('root',
      @attribute_1 = XAttribute.new('attribute_1', 'value'),
      @attribute_2 = XAttribute.new('attribute_2', 'value'),
      @namespace_1 = XNamespace.new('prefix', '/some/url'),
      @child_1 = XElement.new('child',
        @attribute_3 = XAttribute.new('attribute', 'value'),
        @child_2 = XElement.new('child',
          @attribute_4 = XAttribute.new('attribute', 'value')
        )
      ),
      @text_1 = XText.new('some text'),
      @child_3 = XElement.new('child')
    )
  end
  
  def test_order
    nodes = []
    @root.each { | node | nodes << node }

    assert_equal 9, nodes.size
    assert_equal nodes[0], @namespace_1
    assert_equal nodes[1], @attribute_1
    assert_equal nodes[2], @attribute_2
    assert_equal nodes[3], @child_1
    assert_equal nodes[4], @attribute_3
    assert_equal nodes[5], @child_2
    assert_equal nodes[6], @attribute_4
    assert_equal nodes[7], @text_1
    assert_equal nodes[8], @child_3
  end

  def test_find
    result = @root.find { | node | node.path == '/root/child[1]/@attribute' }
    assert_equal @attribute_3, result

    result = @root.find_all { | node | node.path =~ /^.*child\[1\].*$/ }
    assert result.include?(@child_1)
    assert result.include?(@child_2)
    assert result.include?(@child_3) == false
  end

end
