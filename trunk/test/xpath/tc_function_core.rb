require 'roxi'
require 'roxi/xpath'
require 'test/unit'

module ROXI::XPath::Function

  class TestFunctions < Test::Unit::TestCase
    include ROXI
    include ROXI::XPath

    def test_boolean
      context = Context.new

      assert_equal false, Boolean.eval(context, 0.0)
      assert_equal true, Boolean.eval(context, 1.0)
      assert_equal true, Boolean.eval(context, -48962359.0)
      
      assert_equal false, Boolean.eval(context, '')
      assert_equal true, Boolean.eval(context, 'a')

      assert_equal false, Boolean.eval(context, [])
      assert_equal true, Boolean.eval(context, [XElement.new('node')])

      assert_equal true, Boolean.eval(context, XElement.new('node', 'true'))
      assert_equal false, Boolean.eval(context, XElement.new('node', 'false'))

      assert_equal false, Boolean.eval(context, false)
      assert_equal true, Boolean.eval(context, true)
    end

    def test_string
      context = Context.new

      assert_equal '', String.eval(context, '')
      assert_equal 'a', String.eval(context, 'a')

      assert_equal 'false', String.eval(context, false)
      assert_equal 'true', String.eval(context, true)

      assert_equal '0', String.eval(context, 0.0)
      assert_equal '1', String.eval(context, 1.0)

      assert_equal '12345', String.eval(context, 12345.0)
      assert_equal '12345.1', String.eval(context, 12345.1)

      assert_equal 'NaN', String.eval(context, NaN)
      assert_equal 'Infinity', String.eval(context, InfP)
      assert_equal '-Infinity', String.eval(context, InfN)

      assert_equal '', String.eval(context, [])
      assert_equal 'content', String.eval(context, [
        XElement.new('node', 'content'),
        XElement.new('node', 'other')
      ])

      assert_equal 'content', String.eval(context, XElement.new('node', 'content'))
      assert_equal 'content', String.eval(context, XAttribute.new('name', 'content'))
    end

    def test_number
      context = Context.new

      assert_equal 1, Number.eval(context, true)
      assert_equal 0, Number.eval(context, false)

      assert_equal 1, Number.eval(context, 1)
      assert_equal 1.0, Number.eval(context, 1)
      assert_equal 1.0, Number.eval(context, 1.0)
      assert_equal 1, Number.eval(context, 1.0)

      assert_instance_of Float, Number.eval(context, 1)
      assert_instance_of Float, Number.eval(context, 1.0)

      assert_equal(true, Number.eval(context, NaN).nan?)
      assert_equal(1, Number.eval(context, InfP).infinite?)
      assert_equal(-1, Number.eval(context, InfN).infinite?)

      assert_equal 0, Number.eval(context, '0')
      assert_equal 100, Number.eval(context, '100')

      assert_equal 0.0, Number.eval(context, '0.0')
      assert_equal 0.0, Number.eval(context, '.0')
      assert_equal 1.0, Number.eval(context, '1')

      assert_equal true, Number.eval(context, 'fake').nan?

      assert_equal 10, Number.eval(context, [XElement.new('node', '10')])
      assert_equal 10, Number.eval(context, [XAttribute.new('attribute', '10')])

      assert_equal 10, Number.eval(context, XElement.new('node', '10'))
      assert_equal 10, Number.eval(context, XAttribute.new('attribute', '10'))
    end

    def test_ceiling
      context = Context.new
      assert_equal(true, Ceiling.eval(context, NaN).nan?)
      assert_equal(1, Ceiling.eval(context, InfP).infinite?)
      assert_equal(-1, Ceiling.eval(context, InfN).infinite?)
      assert_equal 5.5.ceil, Ceiling.eval(context, '5.5')
    end

    def test_concat
      context = Context.new
      assert_equal 'HelloWorld', Concat.eval(context, 'Hello', 'World')
      assert_equal 'HelloWorldGuys', Concat.eval(context, 'Hello', 'World', 'Guys')
    end

    def test_contains
      context = Context.new
      assert_equal true, Contains.eval(context, 'Hello', 'll')
      assert_equal true, Contains.eval(context, 'Hello', '(.)\1')
      assert_equal false, Contains.eval(context, 'Hello', 'fake')
    end

    def test_count
      context = Context.new
      assert_equal 0, Count.eval(context, [])

      nodes = [ XElement.new('node') ]
      assert_equal 1, Count.eval(context, nodes)

      nodes = [ XElement.new('node'), XElement.new('node'), XElement.new('node') ]
      assert_equal 3, Count.eval(context, nodes)
    end

    def test_floor
      context = Context.new
      assert_equal(true, Floor.eval(context, NaN).nan?)
      assert_equal(1, Floor.eval(context, InfP).infinite?)
      assert_equal(-1, Floor.eval(context, InfN).infinite?)
      assert_equal 5.5.floor, Floor.eval(context, '5.5')
    end

    def test_id
      doc = XDocument.new(
        root = XElement.new('root', XIdAttribute.new('1'),
          child_1 = XElement.new('child', XIdAttribute.new('2'),
            child_1_1 = XElement.new('child', XIdAttribute.new('3'))
          ),
          child_2 = XElement.new('child')
        )
      )
      
      context = Context.new
      context.document = doc

      context.node = root
      assert_equal '1', Id.eval(context, nil)
      
      context.node = child_1
      assert_equal '2', Id.eval(context, nil)

      context.node = nil
      assert_equal [root], Id.eval(context, '1')
      assert_equal [root, child_1_1], Id.eval(context, '1 3')
      assert_equal [root, child_1, child_1_1], Id.eval(context, '1 2 3')

      assert_equal [root], Id.eval(context, [XText.new('1')])
      assert_equal [root], Id.eval(context, XText.new('1'))
    end

    def test_lang
      doc = XDocument.new(
        root = XElement.new('root', XLangAttribute.new('it-IT'),
          attribute_1 = XAttribute.new('nome', 'valore'),
          child_1 = XElement.new('child', XLangAttribute.new('fr-FR'),
            child_1_1 = XElement.new('child', XLangAttribute.new('fr-CA'))
          ),
          child_2 = XElement.new('child')
        )
      )
      
      context = Context.new

      context.node = root
      assert_equal true, Lang.eval(context, 'it')
      assert_equal true, Lang.eval(context, 'it-IT')

      context.node = child_2
      assert_equal true, Lang.eval(context, 'it-IT')

      context.node = attribute_1
      assert_equal true, Lang.eval(context, 'it-IT')

      context.node = child_1_1
      assert_equal true, Lang.eval(context, 'fr')
      assert_equal false, Lang.eval(context, 'fr-FR')
    end

    def test_last
      context = Context.new

      context.nodes = []
      assert_equal 0, Last.eval(context)

      context.nodes = [ XElement.new('node') ]
      assert_equal 1, Last.eval(context)

      context.nodes = [ XElement.new('node'), XElement.new('node'), XElement.new('node') ]
      assert_equal 3, Last.eval(context)
    end

    def test_local_name
      context = Context.new
      nodes = [ XElement.new('prefix:name'), XElement.new('other_prefix:other_name') ]

      context.node = nodes.first
      assert_equal 'name', LocalName.eval(context, nil)

      context.node = nodes.last
      assert_equal 'other_name', LocalName.eval(context, nil)

      context.node = XText.new('some text')
      assert_equal '', LocalName.eval(context, nil)

      context.node = nil
      assert_equal 'name', LocalName.eval(context, nodes)
      assert_equal '', LocalName.eval(context, [])
    end

    def test_name
      context = Context.new
      nodes = [ XElement.new('prefix:name'), XElement.new('other_prefix:other_name') ]

      context.node = nodes.first
      assert_equal 'prefix:name', Name.eval(context, nil)

      context.node = XText.new('some text')
      assert_equal '', Name.eval(context, nil)

      context.node = nil
      assert_equal 'prefix:name', Name.eval(context, nodes)
      assert_equal '', Name.eval(context, [])
    end

    def test_namespace_uri
      context = Context.new
      nodes = [ 
        XElement.new('prefix:name', XNamespace.new('prefix', '/some/url')),
        XElement.new('name')
      ]

      context.node = nodes.first
      assert_equal '/some/url', NamespaceUri.eval(context, nil)

      context.node = nodes.last
      assert_equal '', NamespaceUri.eval(context, nil)

      context.node = XText.new('some text')
      assert_equal '', NamespaceUri.eval(context, nil)

      context.node = nil
      assert_equal '/some/url', NamespaceUri.eval(context, nodes)
      assert_equal '', Name.eval(context, [])
    end

    def test_normalize_space
      context = Context.new
      context.node = XElement.new('node', " some text\nas\telement value ")
      assert_equal 'some text as element value', NormalizeSpace.eval(context, nil)
      assert_equal 'Hello World Guys', NormalizeSpace.eval(context, "\tHello\n World\n\n\nGuys")
    end

    def test_position
      context = Context.new
      context.nodes = [ XElement.new('node'), XElement.new('node') ]

      context.node = context.nodes.first
      assert_equal 1, Position.eval(context)

      context.node = context.nodes.last
      assert_equal 2, Position.eval(context)
    end

    def test_round
      context = Context.new
      assert_equal(true, Round.eval(context, NaN).nan?)
      assert_equal(1, Round.eval(context, InfP).infinite?)
      assert_equal(-1, Round.eval(context, InfN).infinite?)
      assert_equal 5.5.round, Round.eval(context, '5.5')
    end

    def test_starts_with
      context = Context.new
      assert_equal true, StartsWith.eval(context, 'Hello', 'H')
      assert_equal false, StartsWith.eval(context, 'Hello', 'e')
      assert_equal true, StartsWith.eval(context, 'Hello', 'He')
      assert_equal true, StartsWith.eval(context, 'Hello', '')
      assert_equal true, StartsWith.eval(context, 'Hello', 'Hello')
      assert_equal false, StartsWith.eval(context, 'Hello', 'h')
      assert_equal false, StartsWith.eval(context, 'Hello', 'Hello ')
    end

    def test_ends_with
      context = Context.new
      assert_equal true, EndsWith.eval(context, 'Hello', 'o')
      assert_equal false, EndsWith.eval(context, 'Hello', 'l')
      assert_equal true, EndsWith.eval(context, 'Hello', 'llo')
      assert_equal true, EndsWith.eval(context, 'Hello', '')
      assert_equal true, EndsWith.eval(context, 'Hello', 'Hello')
      assert_equal false, EndsWith.eval(context, 'Hello', 'O')
      assert_equal false, EndsWith.eval(context, 'Hello', ' Hello')
    end

    def test_string_length
      context = Context.new
      assert_equal 'Hello'.length, StringLength.eval(context, 'Hello')
      assert_equal 'true'.length, StringLength.eval(context, true)

      context.node = XElement.new('node', 'some text')
      assert_equal 'some text'.length, StringLength.eval(context, nil)
    end

    def test_substring
      context = Context.new
      assert_equal 'Hello', Substring.eval(context, 'Hello', 1)
      assert_equal 'Hel', Substring.eval(context, 'Hello', 1, 3)
      assert_equal 'Hello', Substring.eval(context, 'Hello', 0, 10)
      assert_equal '', Substring.eval(context, 'Hello', 10, 10)
      assert_equal '234', Substring.eval(context, "12345", 1.5, 2.6)
      assert_equal '12', Substring.eval(context, "12345", 0, 3)
      assert_equal '', Substring.eval(context, "12345", NaN, 3)
      assert_equal '', Substring.eval(context, "12345", 1, NaN)
      assert_equal '12345', Substring.eval(context, "12345", -42, InfP)
      assert_equal '', Substring.eval(context, "12345", InfN, InfP)
    end

    def test_substring_after
      context = Context.new
      assert_equal 'lo', SubstringAfter.eval(context, 'Hello', 'el')
      assert_equal 'ello', SubstringAfter.eval(context, 'Hello', 'H')
      assert_equal '', SubstringAfter.eval(context, 'Hello', 'fake')
      assert_equal '', SubstringAfter.eval(context, 'Hello', 'lo')
      assert_equal 'Hello', SubstringAfter.eval(context, 'Hello', '')
      assert_equal '', SubstringAfter.eval(context, 'Hello', 'Hello')
    end

    def test_substring_before
      context = Context.new
      assert_equal 'H', SubstringBefore.eval(context, 'Hello', 'el')
      assert_equal 'He', SubstringBefore.eval(context, 'Hello', 'l')
      assert_equal 'Hell', SubstringBefore.eval(context, 'Hello', 'o')
      assert_equal '', SubstringBefore.eval(context, 'Hello', 'fake')
      assert_equal '', SubstringBefore.eval(context, 'Hello', 'He')
      assert_equal '', SubstringBefore.eval(context, 'Hello', '')
      assert_equal '', SubstringBefore.eval(context, 'Hello', 'Hello')
    end

    def test_sum
      context = Context.new

      nodes = [ XElement.new('node', 5) ]
      assert_equal 5, Sum.eval(context, nodes)

      nodes = []
      assert_equal 0, Sum.eval(context, nodes)

      nodes = [ 
        XElement.new('node', '5'),
        XAttribute.new('name', '10'),
        XText.new('10')
      ]
      assert_equal 25, Sum.eval(context, nodes)
    end
    
    def test_translate
      context = Context.new
      assert_equal 'XML_in_a_Nutshell', Translate.eval(context, 'XML in a Nutshell', ' ', '_')
      assert_equal 'xml in a nutshell', Translate.eval(context, 'XML in a Nutshell', 'XMLN', 'xmln')
      assert_equal 'xml in a utshell', Translate.eval(context, 'XML in a Nutshell', 'XMLN', 'xml')
      assert_equal 'XMLinaNutshell', Translate.eval(context, 'XML in a Nutshell', ' ', '')
    end

  end

end
