require 'roxi'
require 'roxi/xpath'
require 'test/unit'

module ROXI::XPath

  class TestAxis < Test::Unit::TestCase
    include ROXI
    include Axis

    def setup
      document = XDocument.new(
        XElement.new('root',
          XAttribute.new('attribute_1', 'value'),
          XAttribute.new('attribute_2', 'value'),
          XNamespace.new('prefix', '/some/url'),
          XElement.new('child',
            XAttribute.new('attribute', 'value'),
            XElement.new('child',
              XNamespace.new('base', '/other/url'),
              XAttribute.new('attribute', 'value')
            )
          ),
          XText.new('some text'),
          XElement.new('child')
        )
      )
      @document = document
      @root = document.child('root')
    end

    def test_child
      children = Child.walk([@root])
      assert_equal 3, children.size
      assert_equal '/root[1]/child[1]', children[0].path
      assert_equal '/root[1]/text()[2]', children[1].path
      assert_equal '/root[1]/child[3]', children[2].path

      children = Child.walk(children )
      assert_equal 1, children.size
      assert_equal '/root[1]/child[1]/child[1]', children[0].path
    end

    def test_attribute
      attributes = Attribute.walk([@root])
      assert_equal 2, attributes.size
      assert_equal '/root[1]/@attribute_1', attributes[0].path
      assert_equal '/root[1]/@attribute_2', attributes[1].path

      attributes = Attribute.walk([@root, @root.children('child').first])
      assert_equal 3, attributes.size
      assert_equal '/root[1]/@attribute_1', attributes[0].path
      assert_equal '/root[1]/@attribute_2', attributes[1].path
      assert_equal '/root[1]/child[1]/@attribute', attributes[2].path

      attributes = Attribute.walk([@root].concat(@root.children('child')))
      assert_equal 3, attributes.size
      assert_equal '/root[1]/@attribute_1', attributes[0].path
      assert_equal '/root[1]/@attribute_2', attributes[1].path
      assert_equal '/root[1]/child[1]/@attribute', attributes[2].path

      nodes = []
      nodes << @root
      nodes << @root.children('child').first
      nodes << @root.children('child').first.child('child')
      attributes = Attribute.walk(nodes)
      assert_equal 4, attributes.size
      assert_equal '/root[1]/@attribute_1', attributes[0].path
      assert_equal '/root[1]/@attribute_2', attributes[1].path
      assert_equal '/root[1]/child[1]/@attribute', attributes[2].path
      assert_equal '/root[1]/child[1]/child[1]/@attribute', attributes[3].path
    end

    def test_namespace
      namespaces = Namespace.walk([@root])
      assert_equal 1, namespaces.size
      assert_equal '/root[1]/namespace(prefix)', namespaces[0].path

      namespaces = Namespace.walk([@root, @root.children('child').first.child('child')])
      assert_equal 2, namespaces.size
      assert_equal '/root[1]/namespace(prefix)', namespaces[0].path
      assert_equal '/root[1]/child[1]/child[1]/namespace(base)', namespaces[1].path
    end

    def test_descendant
      descendants = Descendant.walk([@root])
      assert_equal 4, descendants.size
      assert_equal '/root[1]/child[1]', descendants[0].path
      assert_equal '/root[1]/child[1]/child[1]', descendants[1].path
      assert_equal '/root[1]/text()[2]', descendants[2].path
      assert_equal '/root[1]/child[3]', descendants[3].path
    end

    def test_descendant_or_self
      descendants = DescendantOrSelf.walk([@root])
      assert_equal 5, descendants.size
      assert_equal '/root[1]', descendants[0].path
      assert_equal '/root[1]/child[1]', descendants[1].path
      assert_equal '/root[1]/child[1]/child[1]', descendants[2].path
      assert_equal '/root[1]/text()[2]', descendants[3].path
      assert_equal '/root[1]/child[3]', descendants[4].path
    end

    def test_parent
      assert_equal '/root[1]', Parent.walk(@root.attributes).only.path
    end

    def test_ancestor
      ancestors = Ancestor.walk(@root.text)
      assert_equal 2, ancestors.size
      assert_equal '/root[1]', ancestors[0].path
      assert_equal '', ancestors[1].path
      
      ancestors = Ancestor.walk([@root.children('child').first.child('child')])
      assert_equal 3, ancestors.size
      assert_equal '/root[1]/child[1]', ancestors[0].path
      assert_equal '/root[1]', ancestors[1].path
      assert_equal '', ancestors[2].path
    end

    def test_ancestor_or_self
      ancestors = AncestorOrSelf.walk(@root.text)
      assert_equal 3, ancestors.size
      assert_equal '/root[1]/text()[2]', ancestors[0].path
      assert_equal '/root[1]', ancestors[1].path
      assert_equal '', ancestors[2].path
    end

    def test_following_sibling
      siblings = FollowingSibling.walk([@root.children('child').first])
      assert_equal 2, siblings.size
      assert_equal '/root[1]/text()[2]', siblings[0].path
      assert_equal '/root[1]/child[3]', siblings[1].path

      siblings = FollowingSibling.walk(@root.text)
      assert_equal 1, siblings.size
      assert_equal '/root[1]/child[3]', siblings[0].path
  
      siblings = FollowingSibling.walk([@root.children('child').last])
      assert_equal 0, siblings.size
      
      siblings = FollowingSibling.walk([@root])
      assert_equal 0, siblings.size
    end

    def test_preceding_sibling
      siblings = PrecedingSibling.walk([@root.children('child').first])
      assert_equal 0, siblings.size

      siblings = PrecedingSibling.walk(@root.text)
      assert_equal 1, siblings.size
      assert_equal '/root[1]/child[1]', siblings[0].path

      siblings = PrecedingSibling.walk([@root.children('child').last])
      assert_equal 2, siblings.size
      assert_equal '/root[1]/text()[2]', siblings[0].path
      assert_equal '/root[1]/child[1]', siblings[1].path
    end

    def test_following
      root = XElement.new('root',
        attribute_1 = XAttribute.new('attribute_1', 'value'),
        attribute_2 = XAttribute.new('attribute_2', 'value'),
        namespace_1 = XNamespace.new('prefix', '/some/url'),
        child_1 = XElement.new('child',
          attribute_3 = XAttribute.new('attribute', 'value'),
          child_2 = XElement.new('child',
            namespace_2 = XNamespace.new('base', '/other/url'),
            attribute_4 = XAttribute.new('attribute', 'value')
          )
        ),
        text_1 = XText.new('some text'),
        child_3 = XElement.new('child',
          attribute_5 = XAttribute.new('attribute', 'value'),
          child_4 = XElement.new('child',
            attribute_6 = XAttribute.new('attribute', 'value')
          )
        ),
        child_6 = XElement.new('child')
      )

      assert_equal [text_1,child_2,child_1], Preceding.walk([child_4])
      assert_equal [child_4,child_3,text_1,child_2,child_1], Preceding.walk([child_6])
    end

    def test_preceding
      root = XElement.new('root',
        attribute_1 = XAttribute.new('attribute_1', 'value'),
        attribute_2 = XAttribute.new('attribute_2', 'value'),
        namespace_1 = XNamespace.new('prefix', '/some/url'),
        child_1 = XElement.new('child',
          attribute_3 = XAttribute.new('attribute', 'value'),
          child_2 = XElement.new('child',
            namespace_2 = XNamespace.new('base', '/other/url'),
            attribute_4 = XAttribute.new('attribute', 'value')
          )
        ),
        text_1 = XText.new('some text'),
        child_3 = XElement.new('child',
          attribute_5 = XAttribute.new('attribute', 'value'),
          child_4 = XElement.new('child',
            attribute_6 = XAttribute.new('attribute', 'value')
          )
        ),
        child_6 = XElement.new('child')
      )

      assert_equal [text_1,child_2,child_1], Preceding.walk([child_4])
      assert_equal [child_4,child_3,text_1,child_2,child_1], Preceding.walk([child_6])
    end

  end

end
