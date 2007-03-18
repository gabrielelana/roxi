require 'roxi'
require 'test/unit'

include ROXI

class TestPath < Test::Unit::TestCase

  def setup
    @root = XElement.new('root')
  end

  def test_path_element
    child = XElement.new('child')
    assert_equal '/child', child.path

    @root << child
    assert_equal '/root/child[1]', child.path
  end

  def test_path_attribute
    attribute = XAttribute.new('attribute', 'value')
    assert_equal '/@attribute', attribute.path

    @root << attribute
    assert_equal '/root/@attribute', attribute.path
  end

  def test_path_namespace
    namespace = XNamespace.new('prefix', '/some/url')
    assert_equal '/namespace(prefix)', namespace.path

    @root << namespace
    assert_equal '/root/namespace(prefix)', namespace.path
  end

  def test_path_text
    text = XText.new('some text')
    assert_equal '/text()', text.path

    @root << text
    assert_equal '/root/text()[1]', text.path

    @root << text = XText.new('other text')
    assert_equal '/root/text()[2]', text.path
  end

  def test_path_comment
    comment = XComment.new('some comment')
    assert_equal '/comment()', comment.path

    @root << comment
    assert_equal '/root/comment()[1]', comment.path
  end

  def test_path_instruction
    instruction = XInstruction.new('php', 'echo "HelloWorld\n";')
    assert_equal '/process-instruction(php)', instruction.path

    @root << instruction
    assert_equal '/root/process-instruction(php)[1]', instruction.path
  end

  def test_path_document
    doc = XDocument.new
    assert_equal '', doc.path

    doc = XDocument.new(
      root = XElement.new('root')
    )
    assert_equal '/root[1]', root.path
  end

end
