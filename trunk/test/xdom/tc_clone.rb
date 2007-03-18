require 'roxi'
require 'test/unit'

include ROXI

class TestClone < Test::Unit::TestCase

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
      @child_3 = XElement.new('child'),
      @comment_1 = XComment.new('some comment'),
      @instruction_1 = XInstruction.new('foo', 'bar')
    )
  end

  def test_clone_element
    root = XElement.new('prefix:root')
    assert_not_nil clone = root.clone
    assert_equal 'prefix:root', clone.qualified_name
  end

  def test_clone_attribute
    attribute = XElement.new('prefix:attribute', 'value')
    assert_not_nil clone = attribute.clone
    assert_equal 'prefix:attribute', clone.qualified_name
  end

  def test_clone_comment
    comment = XComment.new('some comment')
    assert_not_nil clone = comment.clone
    assert_equal 'some comment', clone.value
  end

  def test_clone_text
    text = XText.new('some text')
    assert_not_nil clone = text.clone
    assert_equal 'some text', clone.value
  end

  def test_clone_instruction
    instruction = XInstruction.new('foo', 'bar')
    assert_not_nil clone = instruction.clone
    assert_equal 'foo', clone.processor
    assert_equal 'bar', clone.value
  end

  def test_clone_namespace
    instruction = XNamespace.new('prefix', '/some/url')
    assert_not_nil clone = instruction.clone
    assert_equal 'prefix', clone.name
    assert_equal '/some/url', clone.url
  end

  def test_clone_subtree
    assert_not_nil clone = @child_1.clone
    assert_equal 'child', clone.name
    assert_equal '/child', clone.path
    assert_equal '/child/@attribute', clone.attributes.first.path
    assert_equal '/child/child[1]/@attribute', clone.children.first.attributes.first.path

    assert_not_equal @attribute_3, clone.attributes.first
    assert_not_equal @attribute_4, clone.children.first.attributes.first
  end

end
