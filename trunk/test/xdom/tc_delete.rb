require 'roxi'
require 'test/unit'

include ROXI

class TestDelete < Test::Unit::TestCase

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

  def test_bug
    assert_equal 5, @root.children.size
    @child_1.delete
    assert_equal 4, @root.children.size
  end

  def test_delete_element
    root = XElement.new('root')
    assert_equal root, root.delete

    assert_equal @child_1, @root.find { | n | n.path == '/root/child[1]' }
    assert_equal @root.find { | n | n.path == '/root/child[3]' }, @child_3
    assert @root.children.include?(@child_1)
    assert_equal @child_1, @child_1.delete
    assert_nil @child_1.parent
    assert @root.children.include?(@child_1) == false
    assert_equal @root.find { | n | n.path == '/root/child[2]' }, @child_3
  end

  def test_delete_attribute
    attribute = XAttribute.new('attribute', 'value')
    assert_equal attribute, attribute.delete
    
    assert @root.attributes.include?(@attribute_1)
    assert_equal @attribute_1, @attribute_1.delete
    assert_nil @attribute_1.parent
    assert @root.attributes.include?(@attribute_1) == false
  end

  def test_delete_comment
    assert @root.children.include?(@comment_1)
    assert_equal @comment_1, @comment_1.delete
    assert_nil @comment_1.parent
    assert @root.children.include?(@comment_1) == false
  end

  def test_delete_text
    assert @root.children.include?(@text_1)
    assert_equal @text_1, @text_1.delete
    assert_nil @text_1.parent
    assert @root.children.include?(@text_1) == false
  end

  def test_delete_instruction
    assert @root.children.include?(@instruction_1)
    assert_equal @instruction_1, @instruction_1.delete
    assert_nil @instruction_1.parent
    assert @root.children.include?(@instruction_1) == false
  end

  def test_delete_namespace
    assert @root.namespaces.include?(@namespace_1)
    assert_equal @namespace_1, @namespace_1.delete
    assert_nil @namespace_1.parent
    assert @root.namespaces.include?(@namespace_1) == false
  end

  def test_delete_root
    doc = XDocument.new(
      comment = XComment.new('some comment'),
      root = XElement.new('root')
    )
    assert doc.children.include?(comment)
    assert doc.children.include?(root)

    comment.delete
    assert_nil comment.parent
    assert doc.children.include?(comment) == false
    assert doc.children.include?(root)

    root.delete
    assert_nil root.parent
    assert doc.children.include?(comment) == false
    assert doc.children.include?(root) == false
  end

end
