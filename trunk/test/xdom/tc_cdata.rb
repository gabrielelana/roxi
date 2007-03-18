require 'roxi'
require 'test/unit'

include ROXI

class TestCData < Test::Unit::TestCase

  def test_cdata_value
    data = XCData.new('content')
    assert_equal 'content', data.value
  end

  def test_cdata_invalid
    assert_raise(RuntimeError) {
      XCData.new('text ]]> text')
    }
  end

  def test_cdata_within_element
    root = XElement.new('root',
      XText.new('text'),
      data = XCData.new('content'),
      XText.new('text')
    )
    assert_equal 3, root.children.size
    assert_equal 'textcontenttext', root.value
  end

end
