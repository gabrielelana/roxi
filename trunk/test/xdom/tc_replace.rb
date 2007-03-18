require 'roxi'
require 'test/unit'

include ROXI

class TestReplace < Test::Unit::TestCase

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

  def test_replace_element
    root = XElement.new('root')
    child = XElement.new('child')
    assert_equal root, root.replace(child)

    assert @root.children.include?(@child_1)
    assert_equal @child_1, @child_1.replace(child)

    assert @root.children.include?(child)
    assert_equal @root, child.parent
    assert_nil @child_1.parent
  end

  def test_replace_attribute
    attribute = XAttribute.new('attribute', 'value')
    replace = XAttribute.new('replace', 'value')
    assert_equal attribute, attribute.replace(replace)
    
    assert @root.attributes.include?(@attribute_1)
    assert_equal @attribute_1, @attribute_1.replace(attribute)

    assert @root.attributes.include?(attribute)
    assert @root.attributes.include?(@attribute_1) == false
    assert_equal @root, attribute.parent
    assert_nil @attribute_1.parent
  end

  def test_replace_namespace
    namespace = XNamespace.new('prefix', '/some/url')
    replace = XNamespace.new('prefix', '/some/url')
    assert_equal namespace, namespace.replace(replace)
    
    assert @root.namespaces.include?(@namespace_1)
    assert_equal @namespace_1, @namespace_1.replace(namespace)

    assert @root.namespaces.include?(namespace)
    assert @root.namespaces.include?(@namespace_1) == false
    assert_equal @root, namespace.parent
    assert_nil @namespace_1.parent
  end

  def test_replace_comment
    comment = XComment.new('some comment')
    replace = XComment.new('some replace')
    assert_equal comment, comment.replace(replace)
    
    assert @root.children.include?(@comment_1)
    assert_equal @comment_1, @comment_1.replace(comment)

    assert @root.children.include?(comment)
    assert @root.children.include?(@comment_1) == false
    assert_equal @root, comment.parent
    assert_nil @comment_1.parent
  end

  def test_replace_text
    text = XText.new('some text')
    replace = XText.new('some replace')
    assert_equal text, text.replace(replace)
    
    assert @root.children.include?(@text_1)
    assert_equal @text_1, @text_1.replace(text)

    assert @root.children.include?(text)
    assert @root.children.include?(@text_1) == false
    assert_equal @root, text.parent
    assert_nil @text_1.parent
  end

  def test_replace_instruction
    instruction = XInstruction.new('foo', 'bar')
    replace = XInstruction.new('foo', 'bar')
    assert_equal instruction, instruction.replace(replace)
    
    assert @root.children.include?(@instruction_1)
    assert_equal @instruction_1, @instruction_1.replace(instruction)

    assert @root.children.include?(instruction)
    assert @root.children.include?(@instruction_1) == false
    assert_equal @root, instruction.parent
    assert_nil @instruction_1.parent
  end

  def test_replace_element_with_text
    text = XText.new('some text')

    assert @root.children.include?(@child_1)
    assert_equal '/root/child[1]', @child_1.path
    assert_equal @child_1, @child_1.replace(text)

    assert @root.children.include?(text)
    assert @root.children.include?(@child_1) == false
    assert_equal '/child', @child_1.path
    assert_equal '/root/text()[1]', text.path
  end

  def test_replace_element_with_attribute
    attribute = XAttribute.new('attribute', 'value')
    assert_raise(RuntimeError) { @child_1.replace(attribute) }

    namespace = XNamespace.new('prefix', '/some/url')
    assert_raise(RuntimeError) { @child_1.replace(namespace) }
  end

  def test_replace_root
    doc = XDocument.new(
      comment = XComment.new('some comment'),
      root = XElement.new('root')
    )
    assert doc.children.include?(comment)
    assert doc.children.include?(root)
    
    root.replace(child = XElement.new('child'))
    assert doc.children.include?(comment)
    assert doc.children.include?(child)

    assert doc.children.include?(root) == false
    assert_nil root.parent
  end

end
