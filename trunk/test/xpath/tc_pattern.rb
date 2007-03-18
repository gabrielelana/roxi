require 'roxi'
require 'roxi/xpath'
require 'test/unit'

module ROXI::XPath

  class TestNodePattern < Test::Unit::TestCase
    include ROXI

    def test_node
      pattern = NodePattern::Node.new
      context = Context.new

      assert_equal true, pattern.match(context)
    end

    def test_text
      pattern = NodePattern::Text.new
      context = Context.new

      context.node = ROXI::XText.new('some text')
      assert_equal true, pattern.match(context)

      context.node = ROXI::XComment.new('some comment')
      assert_equal false, pattern.match(context)
    end

    def test_text_with_pattern
      pattern = NodePattern::Text.new('^some')
      context = Context.new
      context.node = ROXI::XText.new('some text')
      assert_equal true, pattern.match(context)

      context.node = XText.new('other text')
      assert_equal false, pattern.match(context)

      pattern = NodePattern::Text.new('^other')
      assert_equal true, pattern.match(context)
    end

    def test_processing_instruction
      pattern = NodePattern::ProcessingInstruction.new
      context = Context.new
      context.node = XInstruction.new('php', 'echo phpinfo();')
      assert_equal true, pattern.match(context)

      context.node = XInstruction.new('ruby', 'puts "HelloWorld\n"')
      assert_equal true, pattern.match(context)

      pattern = NodePattern::ProcessingInstruction.new('php')
      context.node = XInstruction.new('php', 'echo phpinfo();')
      assert_equal true, pattern.match(context)

      context.node = XInstruction.new('ruby', 'puts "HelloWorld\n"')
      assert_equal false, pattern.match(context)
    end

    def test_all
      pattern = NodePattern::All.new
      context = Context.new

      context.node = ROXI::XElement.new('node')
      context.axis = Axis::Child
      assert_equal true, pattern.match(context)

      context.axis = Axis::Attribute
      assert_equal false, pattern.match(context)

      context.axis = Axis::Namespace
      assert_equal false, pattern.match(context)

      context.axis = Axis::Attribute
      context.node = ROXI::XAttribute.new('name', 'value')
      assert_equal true, pattern.match(context)

      context.axis = Axis::Namespace
      assert_equal false, pattern.match(context)

      context.axis = Axis::Attribute
      context.node = ROXI::XNamespace.new('prefix', 'url')
      assert_equal false, pattern.match(context)

      context.axis = Axis::Namespace
      assert_equal true, pattern.match(context)
    end

    def test_name
      root = XElement.new('ns1:root',
        XNamespace.new('ns1', '/some/url'),
        attribute_1 = XAttribute.new('name', 'value'),
        attribute_2 = XAttribute.new('ns1:name', 'value'),
        child_1 = XElement.new('ns1:child',
          XNamespace.new('ns2', '/some/other/url'),
          child_2 = XElement.new('ns2:child', '/some/url')
        ),
        child_3 = XElement.new('child')
      )

      context = Context.new
      context.namespaces = { 'ns1' => '/some/url', 'ns2' => '/some/other/url' }

      context.node = root
      context.axis = Axis::Child
      assert_equal false, NodePattern::Name.new('root').match(context)
      assert_equal false, NodePattern::Name.new('root', 'ns2').match(context)
      assert_equal true, NodePattern::Name.new('root', 'ns1').match(context)
      assert_raise(RuntimeError) { NodePattern::Name.new('root', 'foo').match(context) }

      context.node = attribute_1
      context.axis = Axis::Attribute
      assert_equal true, NodePattern::Name.new('name').match(context)
      assert_equal false, NodePattern::Name.new('name', 'ns1').match(context)

      context.node = attribute_2
      assert_equal true, NodePattern::Name.new('name', 'ns1').match(context)

      context.axis = Axis::Child
      assert_equal false, NodePattern::Name.new('name', 'ns1').match(context)

      context.node = child_3
      context.axis = Axis::Child
      assert_equal false, NodePattern::Name.new('child', 'ns1').match(context)
      assert_equal false, NodePattern::Name.new('name').match(context)
      assert_equal true, NodePattern::Name.new('child').match(context)

      assert_equal true, NodePattern::Pattern.new('^ch').match(context)
    end

    def test_name_with_default_namespace
      root = XElement.new('ns1:root',
        XNamespace.new('', '/default/namespace/url'),
        XNamespace.new('ns1', '/some/url'),
        attribute_1 = XAttribute.new('name', 'value'),
        attribute_2 = XAttribute.new('ns1:name', 'value'),
        child_1 = XElement.new('child')
      )

      context = Context.new
      context.namespaces = {
        'foo' => '/some/url',
        'bar' => '/some/other/url',
        'default' => '/default/namespace/url',
      }

      pattern = NodePattern::Name.new('child', 'default')
      context.node = child_1
      assert_equal true, pattern.match(context)

      pattern = NodePattern::Name.new('name', 'default')
      context.node = attribute_1
      context.axis = Axis::Attribute
      assert_equal false, pattern.match(context)

      pattern = NodePattern::Name.new('name')
      context.node = attribute_1
      context.axis = Axis::Attribute
      assert_equal true, pattern.match(context)
    end

    def test_prefix
      root = XElement.new('ns1:root',
        namespace_1 = XNamespace.new('ns1', '/some/url'),
        attribute_1 = XAttribute.new('name', 'value'),
        attribute_2 = XAttribute.new('ns1:name', 'value'),
        child_1 = XElement.new('ns1:child',
          namespace_2 = XNamespace.new('ns2', '/some/other/url'),
          child_2 = XElement.new('ns2:child', '/some/url')
        )
      )

      context = Context.new
      context.namespaces = { 'foo' => '/some/url', 'bar' => '/some/other/url' }

      pattern = NodePattern::Prefix.new('foo')

      context.node = root
      assert_equal true, pattern.match(context)

      context.node = child_1
      assert_equal true, pattern.match(context)

      context.node = child_2
      assert_equal false, pattern.match(context)

      pattern = NodePattern::Prefix.new('bar')

      context.node = root
      assert_equal false, pattern.match(context)

      context.node = child_1
      assert_equal false, pattern.match(context)

      context.node = child_2
      assert_equal true, pattern.match(context)

      pattern = NodePattern::Prefix.new('fake')
      assert_raise(RuntimeError) { pattern.match(context) }

      pattern = NodePattern::Prefix.new('foo')

      context.node = root
      assert_equal true, pattern.match(context)

      context.node = attribute_1
      context.axis = Axis::Attribute
      assert_equal false, pattern.match(context)

      context.node = attribute_2
      assert_equal true, pattern.match(context)

      pattern = NodePattern::Prefix.new('bar')
      context.node = namespace_2
      assert_equal false, pattern.match(context)
    end

    def test_prefix_with_default_namespace
      root = XElement.new('ns1:root',
        XNamespace.new('', '/default/namespace/url'),
        XNamespace.new('ns1', '/some/url'),
        attribute_1 = XAttribute.new('name', 'value'),
        attribute_2 = XAttribute.new('ns1:name', 'value'),
        child_1 = XElement.new('child')
      )

      context = Context.new
      context.namespaces = {
        'foo' => '/some/url',
        'bar' => '/some/other/url',
        'default' => '/default/namespace/url',
      }

      pattern = NodePattern::Prefix.new('default')
      context.node = child_1
      assert_equal true, pattern.match(context)

      pattern = NodePattern::Prefix.new('default')
      context.node = attribute_1
      context.axis = Axis::Attribute
      assert_equal false, pattern.match(context)
    end

  end

end
