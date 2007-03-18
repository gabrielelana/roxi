require 'roxi'
require 'test/unit'

include ROXI

class TestParent < Test::Unit::TestCase

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
  
  def test_parent
    assert_nil @root.parent
    assert_equal @root, @attribute_1.parent
    assert_equal @root, @text_1.parent
    assert_equal @root, @child_1.parent
    assert_equal @root, @child_3.parent
    assert_equal @child_1.parent, @child_3.parent
    assert_equal @child_1, @attribute_3.parent
    assert_equal @child_1, @child_2.parent
  end
end
