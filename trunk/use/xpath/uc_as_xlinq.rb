require 'roxi/xpath'
require 'test/unit'

include ROXI

class UseAsXLinq < Test::Unit::TestCase

  def initialize(name)
    super(name)
    @customers = File.dirname(__FILE__) + '/../../res/customers.xml'
    @order = File.dirname(__FILE__) + '/../../res/order.xml'
  end

  def test_compute_total_value_order
    total = XDocument.open(@order) do | doc |
      doc.xpath('//item').inject(0) do | total, item |
        price = item.xpath('price').only.to_n
        quantity = item.xpath('quantity').only.to_n
        total += price * quantity
      end
    end
    assert_in_delta 188.93, total, 0.001
  end

  def test_compute_total_value_order_with_facility
    total = XDocument.open(@order) do | doc |
      doc.xpath('//item').inject(0) do | total, item |
        price = item.child('price').to_n
        quantity = item.child('quantity').to_n
        total += price * quantity
      end
    end
    assert_in_delta 188.93, total, 0.001
  end

  def test_compute_total_value_order_more_compact
    total = XDocument.open(@order) do | doc |
      doc.xpath('//item').inject(0) do | total, item |
        total += item.xpath('price * quantity')
      end
    end
    assert_in_delta 188.93, total, 0.001
  end

  def test_compute_total_value_all_with_xpath_extended
    total = XDocument.open(@order).xpath('sum(mul(//item/price, //item/quantity))')
    assert_in_delta 188.93, total, 0.001
  end

  def test_make_new_document_with_query
    doc = XDocument.new(
      XElement.new('contacts',
        XDocument.open(@customers).xpath('//customer').from do | customer |
          XElement.new('contact',
            XAttribute.new('id', customer.child('custno').value),
            XAttribute.new('name', '%s %s' % [
              customer.child('name').child('firstname').value,
              customer.child('name').child('lastname').value
            ])
          )
        end
      )
    )

    result = XDocument.new(
      XElement.new('contacts',
        XElement.new('contact',
          XAttribute.new('id', '9000'),
          XAttribute.new('name', 'Joe Anderson')
        ),
        XElement.new('contact',
          XAttribute.new('id', '1001'),
          XAttribute.new('name', 'Andy Shaperd')
        ),
        XElement.new('contact',
          XAttribute.new('id', '1003'),
          XAttribute.new('name', 'Amanda Johnson')
        ),
        XElement.new('contact',
          XAttribute.new('id', '2005'),
          XAttribute.new('name', 'Bill Murphy')
        )
      )
    )

    assert_equal result.to_s, doc.to_s
  end

end
