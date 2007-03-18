class ::Array
  def only
    unless size == 1
      raise IndexError, "Array#only called on non single element array"
    end
    first
  end
  def from
    builded = []
    each do | item |
      result = yield item
      builded << result if result
    end
    builded
  end
end

class ::Range
  def clip value
    return value if include?(value)
    return first if value < first
    return last if value > last
  end
end

class ::Module
  def const_get_deep(sym)
    sym.to_s.split("::").inject(Object) { | x, y | x = x.const_get(y) }
  end
end

require 'roxi/xdom/xnode'
require 'roxi/xdom/xchild'
require 'roxi/xdom/xcontainer'
require 'roxi/xdom/xdeclaration'
require 'roxi/xdom/xdocument'
require 'roxi/xdom/xname'
require 'roxi/xdom/xnamespace'
require 'roxi/xdom/xattribute'
require 'roxi/xdom/xelement'
require 'roxi/xdom/xcomment'
require 'roxi/xdom/xinstruction'
require 'roxi/xdom/xtext'
require 'roxi/xdom/xparser/xparser'
require 'roxi/xdom/writer'
require 'roxi/xdom/loader'

class ROXI::XDocument
  extend ROXI::Loader
end
