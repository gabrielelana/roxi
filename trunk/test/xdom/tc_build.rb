require 'roxi'
require 'test/unit'

include ROXI

class TestBuild < Test::Unit::TestCase

  def test_build_simple
    root = XElement.new('root')
    assert_equal 'root', root.name

    root = XElement.new('prefix:root')
    assert_equal 'root', root.name
    assert_equal 'prefix:root', root.qualified_name

    root = XElement.new(XName.new('prefix', 'root'))
    assert_equal 'root', root.name
    assert_equal 'prefix', root.prefix
    assert_equal 'prefix:root', root.qualified_name
  end

  def test_build_with_attributes
    root = XElement.new('root',
      attribute_1 = XAttribute.new('attribute_1', '1'))
    assert root.attributes.include?(attribute_1)
    
    root = XElement.new('root',
      attribute_1 = XAttribute.new('attribute_1', '1'),
      attribute_2 = XAttribute.new('attribute_2', '2'))
    assert root.attributes.include?(attribute_1)
    assert root.attributes.include?(attribute_2)

    attribute = XAttribute.new('prefix:attribute', 'value')
    assert_equal 'attribute', attribute.name
    assert_equal 'prefix', attribute.prefix
    assert_equal 'prefix:attribute', attribute.qualified_name

    attribute = XAttribute.new(XName.new('prefix', 'attribute'), 'value')
    assert_equal 'attribute', attribute.name
    assert_equal 'prefix:attribute', attribute.qualified_name
  end

  def test_build_with_array_of_nodes
    root = XElement.new('root', [
      XElement.new('child'),
      XElement.new('child'), [
        XElement.new('child'),
        XElement.new('child'),
      ]
    ])
    assert_equal 4, root.children.size
  end

  def test_order_of_nodes
    root = XElement.new('root', [
      first = XElement.new('child'),
      XElement.new('child'),
      XElement.new('child'),
      last = XElement.new('child'),
    ])
    assert_equal 4, root.children.size
    assert_equal first, root.children.first
    assert_equal last, root.children.last
  end

  def test_build_with_instruction
    root = XElement.new('root',
      instruction = XInstruction.new('php', 'phpinfo();'))
    assert root.children.include?(instruction)
  end

  def test_build_with_namespaces
    root = XElement.new('root',
      namespace = XNamespace.new('prefix', '/some/url'))
    assert root.namespaces.include?(namespace)
    assert_equal 'prefix', namespace.name
    assert_equal '/some/url', namespace.url
  end

  def test_build_with_content
    root = XElement.new('root',
      text = XText.new('some lame text'))
    assert root.children.include?(text)
  end

  def test_with_many_children
    root = XElement.new('root',
      child_1 = XElement.new('child'),
      child_2 = XElement.new('child'))
    assert root.children.include?(child_1)
    assert root.children.include?(child_2)
  end

  def test_with_raw_text
    root = XElement.new('root', 'content')
    assert_equal 'root', root.name
    assert_equal 'content', root.value
  end

  def test_with_objects
    root = XElement.new('root', 'true')
    assert_equal 'true', root.value

    root = XElement.new('root', 1..10)
    assert_equal '1..10', root.value
  end

  def test_build_declaration
    declaration = XDeclaration.new
    assert_equal '1.0', declaration.version
    assert_equal 'utf-8', declaration.encoding
    assert_equal 'yes', declaration.standalone

    declaration = XDeclaration.new(
      XAttribute.new('version', '1.1'),
      XAttribute.new('encoding', 'utf-8'),
      XAttribute.new('standalone', 'no'))
    assert_equal '1.1', declaration.version
    assert_equal 'utf-8', declaration.encoding
    assert_equal 'no', declaration.standalone

    declaration = XDeclaration.new
    declaration.add(XAttribute.new('version', '1.1'))
    assert_equal '1.1', declaration.version
  end

  def test_build_document
    doc = XDocument.new(XElement.new('root'))
    assert_equal '1.0', doc.declaration.version
    assert_equal 'utf-8', doc.declaration.encoding
    assert_equal 'yes', doc.declaration.standalone

    doc.declaration = XDeclaration.new(
      XAttribute.new('version', '1.1'),
      XAttribute.new('encoding', 'utf-8'),
      XAttribute.new('standalone', 'no'))
    assert_equal '1.1', doc.declaration.version
    assert_equal 'utf-8', doc.declaration.encoding
    assert_equal 'no', doc.declaration.standalone

    doc = XDocument.new(
      root = XElement.new('root')
    )
    assert_equal root, doc.child('root')
    assert_equal doc, root.parent

    doc = XDocument.new(
      root = XElement.new('root'),
      XComment.new('some comment'),
      XInstruction.new('foo', 'bar')
    )
    assert doc.children.include?(root)
    assert_equal root, doc.child('root')

    doc = XDocument.new(XElement.new('root'))
    assert_raise(RuntimeError) { doc << XElement.new('root') }
    assert_raise(RuntimeError) { doc << XAttribute.new('attribute', 'value') }
    assert_raise(RuntimeError) { doc << XNamespace.new('prefix', '/some/url') }
  end

end
