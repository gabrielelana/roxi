require 'roxi'
require 'test/unit'

include ROXI

class TestWrap < Test::Unit::TestCase

  def test_wrap_simple
    child = XElement.new('child')
    child.wrap(root = XElement.new('root'))
    assert root.children.include?(child)
    assert_equal '/root/child[1]', child.path
  end

  def test_wrap_in_the_middle
    root = XElement.new('root',
      child_1 = XElement.new('child',
        child_1_1 = XElement.new('child'),
        child_1_2 = XElement.new('child')
      ),
      child_2 = XElement.new('child')
    )
    assert_equal '/root/child[1]/child[1]', child_1_1.path
    assert_equal '/root/child[1]/child[2]', child_1_2.path
    
    child_1.wrap(XElement.new('child'))
    assert_equal '/root/child[1]/child[1]/child[1]', child_1_1.path
    assert_equal '/root/child[1]/child[1]/child[2]', child_1_2.path
  end

  def test_wrap_wrong
    root = XText.new('some text')
    child = XElement.new('child')
    assert_raise(NoMethodError) { child.wrap(root) }
  end
 
end
