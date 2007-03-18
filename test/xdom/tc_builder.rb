require 'roxi'
require 'test/unit'

include ROXI

class TestBuilder < Test::Unit::TestCase

  def setup
    @xml = <<-XML
    <root>
      <node>some text</node>
      <node>some other text</node>
    </root>
    XML
    @xml.gsub!(/^\s*/, '')

    @doc = XDocument.new(
      XElement.new('root',
        XElement.new('node', 'some text'),
        XElement.new('node', 'some other text')
      )
    )
  end

  def test_build_with_string
    doc = XDocument.string(@xml)
    assert_equal @doc.to_s, doc.to_s
  end

  def test_build_and_block
    XDocument.string(@xml) do | doc |
      assert_equal @doc.to_s, doc.to_s
    end
  end

end
