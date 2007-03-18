require 'roxi/xupdate'
require 'test/unit'

include ROXI

# examples from http://www.xmldatabases.org/projects/XUpdate-UseCases/
class XUpdateExamples < Test::Unit::TestCase

  def setup
    @xml = <<-XML
      <addresses>
        <address id="1">
          <!--This is the users name-->
          <name>
            <first>John</first>
            <last>Smith</last>
          </name>      
          <city>Houston</city>
          <state>Texas</state>
          <country>United States</country>
          <phone type="home">333-300-0300</phone>
          <phone type="work">333-500-9080</phone>
          <note><![CDATA[This is a new user]]></note>
        </address>
      </addresses>
    XML
  end

  def test_insert_before
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #   <xupdate:insert-before select="/addresses/address[@id = 1]/name/last" >   
    #     <xupdate:element name="middle">Lennox</xupdate:element>      
    #   </xupdate:insert-before>
    # </xupdate:modifications>
    
    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]/name/last') do | node |
        node.insert_before(XElement.new('middle', 'Lennox'))
      end
    end
    assert_equal 'Lennox', doc.xpath('//middle').only.value
  end

  def test_insert_attribute
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #   <xupdate:append select="/addresses/address[@id = 1]/phone[@type='work']" >   
    #     <xupdate:attribute name="extension">223</xupdate:attribute>      
    #   </xupdate:append>
    # </xupdate:modifications> 
    #
    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]/phone[@type="work"]') do | node |
        node.append(XAttribute.new('extension', 223))
      end
    end
    assert_equal 223, doc.xpath('//phone[@type="work"]/@extension').only.to_i
  end

  def test_insert_xml_block
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #   <xupdate:append select="/addresses" >
    #     <xupdate:element name="address">
    #       <xupdate:attribute name="id">2</xupdate:attribute>
    #       <name>
    #         <first>Susan</first>
    #         <last>Long</last>
    #       </name>
    #       <city>Tucson</city>
    #       <state>Arizona</state>
    #       <country>United States</country>
    #       <phone type="home">430-304-3040</phone>
    #     </xupdate:element>      
    #   </xupdate:append>
    # </xupdate:modifications> 

    doc = XDocument.string(@xml).update do
      select('/addresses') do | node |
        node.append(
          XElement.new('address',
            XAttribute.new('id', 2),
            XElement.new('name',
              XElement.new('first', 'Susan'),
              XElement.new('last', 'Long')
            ),
            XElement.new('city', 'Tucson'),
            XElement.new('state', 'Arizona'),
            XElement.new('country', 'United States'),
            XElement.new('phone', '430-304-3040',
              XAttribute.new('type', 'home')
            )
          )
        )
      end
    end
    
    assert_equal 'Susan', doc.xpath('/addresses/address[@id=2]/name/first').only.value
    assert_equal 'Susan', doc.xpath('string(/addresses/address[@id=2]/name/first)')
  end

  def test_update_element
    # NOTE: not quite correct, what if there are not only one text child for node first?
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #   <xupdate:update select="/addresses/address[@id = 1]/name/first">Johnathan</xupdate:update>
    # </xupdate:modifications>

    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]/name/first/text()[1]') do | node |
        node.replace(XText.new('Johnathan'))
      end
    end
    assert_equal 'Johnathan', doc.xpath('//first/text()[1]').only.value
  end

  def test_update_attribute
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #    <xupdate:update select="/addresses/address[@id = 1]/phone[.='333-300-0300']/@type" >cell</xupdate:update>
    # </xupdate:modifications>

    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]/phone[.="333-300-0300"]/@type') do | attribute |
        attribute.value = 'cell'
      end
    end
    assert_equal 'cell', doc.xpath('/addresses/address[@id=1]/phone[.="333-300-0300"]/@type').only.value
  end

  def test_rename_element
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #    <xupdate:rename select="/addresses/address[@id = 1]/note" >comment</xupdate:rename>
    # </xupdate:modifications> 

    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]/note') do | element |
        element.name = 'comment'
      end
    end
    assert_equal 1, doc.xpath('/addresses/address[@id=1]/comment').size
    assert_equal 0, doc.xpath('/addresses/address[@id=1]/note').size
  end

  def test_delete_element
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #   <xupdate:remove select="/addresses/address[@id = 1]/phone"/>
    # </xupdate:modifications> 

    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]/phone') do | node |
        node.delete
      end
    end
    assert_equal 0, doc.xpath('/addresses/address[@id=1]/phone').size

    # a better way
    doc = XDocument.string(@xml).update do
      remove('/addresses/address[@id=1]/phone')
    end
    assert_equal 0, doc.xpath('/addresses/address[@id=1]/phone').size
  end

  def test_copy_a_node
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #   <xupdate:variable name="state" select="/addresses/address[@id = 1]/state"/>
    #   <xupdate:insert-after select="/addresses/address[@id = 1]/country">
    #     <xupdate:value-of select="$state"/>
    #   </xupdate:insert-after>
    # </xupdate:modifications>

    # translation
    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]/state') do | node |
        @state = node.clone
      end
      select('/addresses/address[@id=1]/country') do | node |
        node.insert_after(@state)
      end
    end
    assert_equal 2, doc.xpath('//state').size

    # a better way
    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]') do | node |
        node.child('country').insert_after(node.child('state').clone)
      end
    end
    assert_equal 2, doc.xpath('//state').size
  end

  def test_moving_a_node
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #   <xupdate:variable name="country" select="/addresses/address[@id = 1]/country"/>
    #   <xupdate:remove select="/addresses/address[@id = 1]/country"/>
    #   <xupdate:insert-before select="/addresses/address[@id = 1]/state">
    #     <xupdate:value-of select="$country"/>
    #   </xupdate:insert-before>   
    # </xupdate:modifications>

    # translation
    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]/country') do | country |
        @country = country.clone
      end
      remove('/addresses/address[@id=1]/country')
      select('/addresses/address[@id=1]/state') do | state |
        state.insert_before(@country)
      end
    end

    assert_equal '/addresses[1]/address[1]/country[4]', doc.xpath('//country').only.path
    assert_equal '/addresses[1]/address[1]/state[5]', doc.xpath('//state').only.path

    # a better way
    doc = XDocument.string(@xml).update do
      select('/addresses/address[@id=1]') do | address |
        address.child('country').insert_after(address.child('state').delete)
      end
    end

    assert_equal '/addresses[1]/address[1]/country[4]', doc.xpath('//country').only.path
    assert_equal '/addresses[1]/address[1]/state[5]', doc.xpath('//state').only.path
  end

end
