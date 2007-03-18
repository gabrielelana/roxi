require 'roxi'
require 'test/unit'

include ROXI

class TestInsert < Test::Unit::TestCase
  
  def test_insert_simple
    root = XElement.new('root')
    child = XElement.new('child')
    after = XElement.new('after')
    before = XElement.new('before')

    root << child
    assert_equal '/root/child[1]', child.path

    child.insert_before(before)
    assert_equal '/root/before[1]', before.path
    assert_equal '/root/child[2]', child.path

    child.insert_after(after)
    assert_equal '/root/child[2]', child.path
    assert_equal '/root/after[3]', after.path
  end

  def test_insert_silent
    child = XElement.new('child')
    after = XElement.new('after')
    before = XElement.new('before')

    assert_equal child, child.insert_before(before)
    assert_equal child, child.insert_after(after)

    assert_equal '/child', child.path
    assert_equal '/before', before.path
    assert_equal '/after', after.path
  end

  def test_insert_direct
    root = XElement.new('root',
      child = XElement.new('child'))

    root.insert_node_before(before = XElement.new('before'), child)
    assert_equal '/root/child[2]', child.path
    assert_equal '/root/before[1]', before.path

    root.insert_node_after(after = XElement.new('after'), child)
    assert_equal '/root/child[2]', child.path
    assert_equal '/root/after[3]', after.path
  end

  def test_insert_around_root
    doc = XDocument.new(
      comment = XComment.new('some comment'),
      root = XElement.new('root')
    )
    assert_equal '/comment()[1]', comment.path
    assert_equal '/root[2]', root.path
    
    root.insert_before(text_before = XComment.new('before'))
    root.insert_after(text_after = XComment.new('after'))
    assert_equal '/comment()[2]', text_before.path
    assert_equal '/comment()[4]', text_after.path
    assert_equal '/root[3]', root.path

    assert_raise(RuntimeError) { root.insert_before(XElement.new('child')) }
    assert_raise(RuntimeError) { root.insert_after(XElement.new('child')) }
  end

  def test_insert_between_tree
    root_1 = XElement.new('root', child_1 = XElement.new('child'))
    root_2 = XElement.new('root', child_2 = XElement.new('child'))

    child_1.insert_after(child_2)

    assert_equal 2, root_1.children.size
    assert_equal child_1, root_1.children.first
    assert_not_equal child_2, root_1.children.last
  end

end
