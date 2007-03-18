require 'roxi/xpath'
require 'test/unit'

include ROXI

# examples from http://www.xmldatabases.org/projects/XUpdate-UseCases/
class UseAsXUpdate < Test::Unit::TestCase

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
    
    doc = XDocument.string(@xml) do | doc |
      doc.xpath('/addresses/address[@id=1]/name/last').only.
        insert_before(XElement.new('middle', 'Lennox'))
      doc
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

    doc = XDocument.string(@xml) do | doc |
      doc.xpath('/addresses/address[@id=1]/phone[@type="work"]').only.
        add(XAttribute.new('extension', 223))
      doc
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

    doc = XDocument.string(@xml)
    doc.child('addresses').append(
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

    assert_equal 'Susan', doc.xpath('/addresses/address[@id=2]/name/first').only.value
    assert_equal 'Susan', doc.xpath('string(/addresses/address[@id=2]/name/first)')
  end


  def test_moving_a_node
    # <xupdate:modifications version="1.0" xmlns:xupdate="http://www.xmldb.org/xupdate">
    #   <xupdate:variable name="country" select="/addresses/address[@id = 1]/country"/>
    #   <xupdate:remove select="/addresses/address[@id = 1]/country"/>
    #   <xupdate:insert-before select="/addresses/address[@id = 1]/state">
    #     <xupdate:value-of select="$country"/>
    #   </xupdate:insert-before>   
    # </xupdate:modifications>

    doc = XDocument.string(@xml)
    doc.xpath('/addresses/address[@id=1]').only.child('country').
      insert_after(doc.xpath('/addresses/address[@id=1]').only.child('state').delete)

    assert_equal '/addresses[1]/address[1]/country[4]', doc.xpath('//country').only.path
    assert_equal '/addresses[1]/address[1]/state[5]', doc.xpath('//state').only.path
  end

end
