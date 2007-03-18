require 'roxi'
require 'test/unit'

include ROXI

class TestWriter < Test::Unit::TestCase

  def test_simple
    writer = Writer.new(XElement.new('root'))
    assert_equal "<root />\n", writer.pretty
  end

  def test_with_attributes
    root = XElement.new('root',
      XAttribute.new('attribute_1', 'value'),
      XAttribute.new('attribute_2', 'value')
    )
    out = <<-XML
    <root attribute_1="value" attribute_2="value" />
    XML
    out.gsub!(/^ */, '')
    assert_equal out, Writer.new(root).pretty
  end

  def test_with_namespace
    root = XElement.new('root',
      XNamespace.new('prefix', '/some/url'),
      XAttribute.new('attribute', 'value')
    )
    out = <<-XML
    <root xmlns:prefix="/some/url" attribute="value" />
    XML
    out.gsub!(/^ */, '')
    assert_equal out, Writer.new(root).pretty
  end

  def test_with_text
    root = XElement.new('root',
      XAttribute.new('attribute', 'value'),
      XText.new("some text\nmulti line")
    )
    out = <<-XML
    <root attribute="value">
    \tsome text
    \tmulti line
    </root>
    XML
    out.gsub!(/^ */, '')
    assert_equal out, Writer.new(root).pretty
  end

  def test_with_children
    root = XElement.new('root',
      XAttribute.new('attribute', 'value'),
      XElement.new('child',
        XElement.new('child')
      ),
      XComment.new('some comment'),
      XInstruction.new('php', 'echo "HelloWorld";'),
      XElement.new('child')
    )
    out = <<-XML
    <root attribute="value">
    \t<child>
    \t\t<child />
    \t</child>
    \t<!-- some comment -->
    \t<?php echo "HelloWorld";?>
    \t<child />
    </root>
    XML
    out.gsub!(/^ */, '')
    assert_equal out, Writer.new(root).pretty
    assert_equal out, root.to_s
  end

  def test_with_document
    doc = XDocument.new(
      XInstruction.new('xml-stylesheet', 'href="person.css" type="text/css"'),
      XComment.new('some comment'),
      XElement.new('person',
        XText.new('Alan Turing')
      ),
      XComment.new('some comment')
    )
    out = <<-XML
    <?xml version="1.0" encoding="utf-8" standalone="yes"?>
    <?xml-stylesheet href="person.css" type="text/css"?>
    <!-- some comment -->
    <person>
    \tAlan Turing
    </person>
    <!-- some comment -->
    XML
    out.gsub!(/^ */, '')
    assert_equal out, Writer.new(doc).pretty
    assert_equal out, doc.to_s
  end

end
