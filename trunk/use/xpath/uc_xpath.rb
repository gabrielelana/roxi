require 'roxi/xpath'
require 'test/unit'

include ROXI

class UseXPath < Test::Unit::TestCase

  def initialize(name)
    super(name)
    @customers = XDocument.open(File.dirname(__FILE__) + '/../../res/customers.xml')
  end

  def test_external_variables_usage
    custno_1 = @customers.xpath('//customer/custno')
    custno_2 = @customers.xpath('(//customer)/custno')

    context = XPath::Context.new
    context.variables['all_customers'] = @customers.xpath('//customer')
    custno_3 = @customers.xpath('$all_customers/custno', context)

    assert_equal custno_1, custno_2
    assert_equal custno_1, custno_3
  end

  def test_document_order
    custno = @customers.xpath('//custno[.="2005"] | //custno[.="9000"]')
    assert_equal "2005", custno.first.value
    assert_equal "9000", custno.last.value

    # not quite correct, not in document order, but...
    # not done autmaticaly because can be quite expensive
    custno = @customers.xpath('sort-in-document-order(//custno[.="2005"] | //custno[.="9000"])')
    assert_equal "9000", custno.first.value
    assert_equal "2005", custno.last.value

    # if you need values instead of elements
    assert_equal ['9000', '2005'], @customers.xpath('strings(sort-in-document-order(//custno[.="2005"] | //custno[.="9000"]))')
    assert_equal [9000, 2005], @customers.xpath('numbers(sort-in-document-order(//custno[.="2005"] | //custno[.="9000"]))')

    # a better way
    context = XPath::Context.new
    context.variables['partial'] = @customers.xpath('//custno[.="2005"] | //custno[.="9000"]')
    assert_equal ['9000', '2005'], @customers.xpath('strings(sort-in-document-order($partial))', context)
    assert_equal [9000, 2005], @customers.xpath('numbers(sort-in-document-order($partial))', context)

    # a shortcut
    $partial = @customers.xpath('//custno[.="2005"] | //custno[.="9000"]')
    assert_equal ['9000', '2005'], @customers.xpath('strings(sort-in-document-order($partial))')
    assert_equal [9000, 2005], @customers.xpath('numbers(sort-in-document-order($partial))')

    # another way
    partial = @customers.xpath('//custno[.="2005"] | //custno[.="9000"]')
    assert_equal ['9000', '2005'], XPath.from(partial).eval('strings(sort-in-document-order(.))')
    assert_equal [9000, 2005], XPath.from(partial).eval('numbers(sort-in-document-order(.))')
  end

end
