require 'roxi'
require 'test/unit'

include ROXI

class TestContainer < Test::Unit::TestCase

  def setup
    @root = XElement.new('root',
      @attribute_1 = XAttribute.new('attribute_1', 'value'),
      @attribute_2 = XAttribute.new('attribute_2', 'value'),
      @child_1 = XElement.new('child',
        @attribute_1_1 = XAttribute.new('attribute', 'value'),
        @child_1_1 = XElement.new('child',
          @attribute_1_1_1 = XAttribute.new('attribute', 'value')
        )
      ),
      @child_2 = XElement.new('child'),
      @child_3 = XElement.new('child'),
      @child_4 = XElement.new('child'),
      @child_5 = XElement.new('child')
    )
  end

  def test_children_with_name
    assert_equal 5, @root.children.size
    assert_equal 5, @root.children('child').size
    assert_equal 5, @root.children(/^ch.*$/).size
    assert_equal true, @root.children?('child')
    assert_equal 0, @root.children('fake').size
    assert_equal false, @root.children?('fake')

    root = XElement.new('root',
      XElement.new('prefix:child'))
    assert_equal 0, root.children('child').size
    assert_equal 1, root.children('prefix:child').size
  end

  def test_child_with_name
    assert_equal @child_1_1, @child_1.child('child')
    assert_equal true, @child_1.child?('child')
    assert_raise(RuntimeError) { @root.child('child') }
    assert_raise(RuntimeError) { @root.child('fake') }
    assert_equal false, @root.child?('fake')

    root = XElement.new('root',
      child = XElement.new('prefix:child'))
    assert_equal child, root.child('prefix:child')
  end
  
  def test_child_mixed
    root = XElement.new('root',
      XText.new('some text'),
      XComment.new('some comment'),
      XInstruction.new('foo', 'bar'),
      child = XElement.new('child'))
    assert_equal child, root.child('child')
  end

  def test_attributes_with_name
    assert_equal 2, @root.attributes(/attribute/).size
    assert_equal true, @root.attributes?(/attribute/)
    assert_equal 1, @root.attributes('attribute_1').size
    assert_equal 0, @root.attributes('fake').size
    assert_equal false, @root.attributes?('fake')

    root = XElement.new('root',
      XAttribute.new('prefix:attribute', 'value'))
    assert_equal 0, root.attributes('child').size
    assert_equal 1, root.attributes('prefix:attribute').size
  end

  def test_attribute_with_name
    assert_equal @attribute_1, @root.attribute('attribute_1')
    assert_equal true, @root.attribute?('attribute_1')
    assert_raise(RuntimeError) { @root.attribute(/attribute/) }
    assert_raise(RuntimeError) { @root.attribute('fake') }
    assert_equal false, @root.attribute?('fake')

    root = XElement.new('root',
      attribute = XAttribute.new('prefix:attribute', 'value'))
    assert_equal attribute, root.attribute('prefix:attribute')
  end

  def test_text_value
    root = XElement.new('root', 'true')
    assert_equal 'true', root.value
    assert_equal 'true', root.text.only.value

    root.text.only.value = 'false'
    assert_equal 'false', root.value
    assert_equal 'false', root.text.only.value
  end

  def test_position
    assert_equal 1, @root.position(@child_1)
    assert_equal 2, @root.position(@child_2)
    assert_equal 3, @root.position(@child_3)
    assert_equal 4, @root.position(@child_4)
    assert_equal 5, @root.position(@child_5)
    assert_equal 1, @child_1.position(@child_1_1)
  end

  def test_following_sibling
    assert_equal 4, @root.following_sibling(@child_1).size
    assert_equal 1, @root.following_sibling(@child_4).size
    assert_equal 0, @root.following_sibling(@child_5).size

    following_sibling = @root.following_sibling(@child_1)
    assert following_sibling.include?(@child_2)
    assert following_sibling.include?(@child_5)
    assert following_sibling.include?(@child_1) == false

    assert @root.following_sibling(@child_4).include?(@child_5)
  end

  def test_preceding_sibling
    assert_equal 0, @root.preceding_sibling(@child_1).size
    assert_equal 1, @root.preceding_sibling(@child_2).size
    assert_equal 4, @root.preceding_sibling(@child_5).size

    assert @root.preceding_sibling(@child_2).include?(@child_1)
  end

end
