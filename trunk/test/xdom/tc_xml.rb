require 'roxi'
require 'test/unit'

include ROXI

class TestSpecialAttributes < Test::Unit::TestCase

  def test_id_nil
    root = XElement.new('root')
    assert_nil root.id
  end

  def test_id_fake
    root = XElement.new('root', XAttribute.new('id', 'value'))
    assert_nil root.id
  end

  def test_id_simple
    root = XElement.new('root', XIdAttribute.new('value'))
    assert_equal 'value', root.id
  end

  def test_id_overload
    root = XElement.new('root',
      XIdAttribute.new('value'),
      XIdAttribute.new('other'))
    assert_equal 'value', root.id
  end

  def test_id_override
    root = XElement.new('root',
      XIdAttribute.new('value'),
      child = XElement.new('child'))
    assert_equal 'value', root.id
    assert_nil child.id
  end


  def test_lang_nil
    root = XElement.new('root')
    assert_nil root.lang
  end

  def test_lang_fake
    root = XElement.new('root', XAttribute.new('lang', 'it'))
    assert_nil root.lang
  end

  def test_lang_simple
    root = XElement.new('root', XLangAttribute.new('it'))
    assert_equal 'it', root.lang
  end

  def test_lang_inherit
    root = XElement.new('root',
      XLangAttribute.new('it'),
      child = XElement.new('child'))
    assert_equal 'it', child.lang
  end

  def test_lang_others
    root = XElement.new('root',
      XLangAttribute.new('it'),
      attribute = XAttribute.new('node', 'value'),
      text = XText.new('testo'))
    assert_equal 'it', attribute.lang
    assert_equal 'it', text.lang
  end

  def test_lang_ovveride
    root = XElement.new('root',
      XLangAttribute.new('it'),
      child = XElement.new('child',
        XLangAttribute.new('us')))
    assert_equal 'us', child.lang
    assert_equal 'it', root.lang
  end


  def test_base_nil
    root = XElement.new('root')
    assert_nil root.url
  end

  def test_base_fake
    root = XElement.new('root', XAttribute.new('base', '/some/url/'))
    assert_nil root.url
  end

  def test_base_simple
    root = XElement.new('root', XBaseAttribute.new('/some/url/'))
    assert_equal '/some/url/', root.url
  end

  def test_base_inherit
    root = XElement.new('root',
      XBaseAttribute.new('/some/url/'),
      child = XElement.new('child'))
    assert_equal '/some/url/', child.url
  end

  def test_base_override
    root = XElement.new('root',
      XBaseAttribute.new('/some/url/'),
      child = XElement.new('child',
        XBaseAttribute.new('/some/other/url/')))
    assert_equal '/some/other/url/', child.url
    assert_equal '/some/url/', root.url
  end

  def test_base_resolve_relative_url
    root = XElement.new('root', XBaseAttribute.new('/some/url/'))
    assert_equal '/some/url/', root.url
    assert_equal '/some/url/from/base', root.url('from/base')
  end

end
