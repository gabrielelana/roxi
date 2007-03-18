require 'roxi'
require 'test/unit'

include ROXI

class TestUpdate < Test::Unit::TestCase

  def setup
    @doc = XDocument.new(
      @root = XElement.new('root',
      @attribute_1 = XAttribute.new('attribute_1', 'value'),
      @attribute_2 = XAttribute.new('attribute_2', 'value'),
      @namespace_1 = XNamespace.new('prefix', '/some/url'),
      @child_1 = XElement.new('child',
        @attribute_3 = XAttribute.new('attribute', 'value'),
        @child_2 = XElement.new('prefix:child',
          @attribute_4 = XAttribute.new('attribute', 'value')
        )
      ),
      @text_1 = XText.new('some text'),
      @child_3 = XElement.new('child'),
      @comment_1 = XComment.new('some comment'),
      @instruction_1 = XInstruction.new('foo', 'bar')
    ))
  end

  def test_update_attribute_name
    @attribute_1.name = 'foo'
    assert_equal '/root[1]/@foo', @attribute_1.path
  end

  def test_update_element_name
    @child_1.name = 'foo'
    assert_equal '/root[1]/foo[1]/@attribute', @attribute_3.path
  end

  def test_update_namespace_name
    @namespace_1.name = 'foo'
    assert_equal '/root[1]/namespace(foo)', @namespace_1.path
  end

  def test_update_element_prefix
    @child_3.prefix = 'foo'
    assert_equal 'foo:child', @child_3.qualified_name
  end

  def test_update_attribute_value
    assert @attribute_1.value = 'foo'
  end

  def test_update_namespace_value
    assert @namespace_1.value = 'foo'
    assert @namespace_1.url = 'foo'
  end

  def test_update_comment_value
    assert @comment_1.value = 'foo'
  end

  def test_update_instruction_value
    assert @instruction_1.value = 'foo'
  end

  def test_update_text_value
    assert @text_1.value = 'foo'
  end

end
