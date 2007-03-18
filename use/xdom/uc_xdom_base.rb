require 'roxi'
require 'test/unit'

include ROXI

class UseXDomBase < Test::Unit::TestCase

  def setup
    @xml = <<-XML
    <?xml version="1.0" encoding="utf-8"?>
    <chapter>
        <title>Data Model</title>
        <section>
            <title>Syntax For Data Model</title>
        </section>
        <section>
            <title>XML</title>
            <section>
                <title>Basic Syntax</title>
            </section>
            <section>
                <title>XML and Semistructured Data</title>
            </section>
        </section>
    </chapter>
    XML
  end

  def test_build_element
    element = XElement.new('root')
    assert_equal 'root', element.name
    assert_equal '', element.value

    element = XElement.new('root', XText.new('some content'))
    assert_equal 'some content', element.value

    element = XElement.new('root', 'some content')
    assert_equal 'some content', element.value
  end

  def test_build_elements
    root = XElement.new('root', XElement.new('child'))
    assert_equal 'child', root.child('child').name

    root = XElement.new('root', XAttribute.new('attribute', 'value'))
    assert_equal 'value', root.attribute('attribute').value

    root = XElement.new('root',
      XAttribute.new('attribute', 'value'),
      XElement.new('child')
    )
    assert_equal 'child', root.child('child').name
    assert_equal 'value', root.attribute('attribute').value
  end

  def test_build_with_literals
    element = XElement.new('root', 1)
    assert_equal '1', element.value
    
    element = XElement.new('root', Object.new)
    assert element.value.instance_of?(String)
  end

  def test_build_with_array
    children = [ XElement.new('child'), XElement.new('child'), XElement.new('child') ]
    element = XElement.new('root', children)
    assert_equal 3, element.children.size

    element = XElement.new('root').add(children)
    assert_equal 3, element.children.size
  end

  def test_path
    # xpath like path attribute as identifier
    root = XElement.new('root')
    assert_equal '/root', root.path

    document = XDocument.new(root)
    assert_equal '/root[1]', root.path

    root.add(child = XElement.new('child'))
    assert_equal '/root[1]/child[1]', child.path

    attribute = XAttribute.new('name', 'value')
    assert_equal '/@name', attribute.path

    root.add(attribute)
    assert_equal '/root[1]/@name', attribute.path
  end

  def test_simple_navigation
    doc = XDocument.string(@xml)

    assert_equal true, doc.child?('chapter')
    assert_equal 'Data Model', doc.child('chapter').child('title').value

    chapter = doc.child('chapter')
    assert_equal true, chapter.children?('section')
    assert_equal 2, chapter.children('section').size
    assert_equal 2, chapter.children(/^se.*$/).size
  end

  def test_traverse_with_each
    doc = XDocument.string(@xml)

    # document order traversal
    doc.each { | node | node.path }

    # find all elements title
    # gook for quick seach without xpath
    titles = doc.select do | node |
      if node.instance_of? XElement
        node if node.name == 'title'
      end
    end
    assert_equal 5, titles.size

    # find all elements title children of section
    titles = doc.select do | node |
      if node.instance_of? XElement
        node if node.name == 'title' and node.parent.name == 'section'
      end
    end
    assert_equal 4, titles.size

    # find all elements title children of section children
    # of section children of chapter
    titles = doc.select do | node |
      if node.instance_of? XElement
        node if node.path =~ /^\/chapter\[\d+\](?:\/section\[\d+\]){2}\/title\[\d+\]$/
      end
    end
    assert_equal 2, titles.size
  end

  def test_id
    # dtd is not supported but identifier can be applited
    # at elements through xml:id attribute
    assert_equal 'first', XElement.new('root', XIdAttribute.new('first')).id
  end


end
