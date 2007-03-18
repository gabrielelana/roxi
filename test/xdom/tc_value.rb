require 'roxi'
require 'test/unit'

include ROXI

class TestValue < Test::Unit::TestCase

  def test_value_of_element
    root = XElement.new('root')
    assert_equal '', root.value

    root << XText.new(text_1 = 'some text')
    root << XText.new(text_2 = 'other text')
    assert_equal text_1 + text_2, root.value
  end

  def test_value_of_text
    text = XText.new('some text')
    assert_equal 'some text', text.value
  end

  def test_value_of_attribute
    attribute = XAttribute.new('name', 'value')
    assert_equal 'value', attribute.value
  end
  
  def test_value_of_instruction
    instruction = XInstruction.new('php', value = 'echo "HelloWorld\n";')
    assert_equal value, instruction.value
  end

  def test_value_of_comment
    comment = XComment.new('some comment')
    assert_equal 'some comment', comment.value
  end
  
  def test_value_of_namespace
    namespace = XNamespace.new('prefix', '/some/url')
    assert_equal '/some/url', namespace.value
  end

  def test_value_integer_cast
    assert_equal 3,
      XAttribute.new('value', '1').to_i +
      XAttribute.new('value', '2').to_i
    assert_raise(RuntimeError) { XAttribute.new('value', 'value').to_i }
  end

  def test_value_float_cast
    assert_equal 3.2, 
      XElement.new('elem', '1.1').to_f +
      XElement.new('elem', '2.1').to_f
    assert_raise(RuntimeError) { XAttribute.new('value', 'value').to_f }

    assert_equal 3.2, 
      XElement.new('elem', 1.1).to_f +
      XElement.new('elem', 2.1).to_f
    assert_raise(RuntimeError) { XAttribute.new('value', 'value').to_f }
  end

  def test_value_boolean_cast
    assert_equal true, XAttribute.new('value', 'true').to_b
    assert_equal true, XAttribute.new('value', 'yes').to_b
    assert_equal true, XAttribute.new('value', '1').to_b
    assert_equal false, XAttribute.new('value', 'false').to_b
    assert_equal false, XAttribute.new('value', 'no').to_b
    assert_equal false, XAttribute.new('value', '0').to_b
    assert_raise(RuntimeError) { XAttribute.new('value', 'value').to_b }
  end

end
