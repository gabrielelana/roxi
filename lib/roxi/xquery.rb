class Array
  def Array.cartesian(base, *others)
    return base.map { | a | [a] } if others.empty?
    others = Array.cartesian(*others)
    base.inject([]) { | r, a |
      others.inject(r) { | r, b |
        r << ([a, *b])
      }
    }
  end 
end

require 'roxi'
require 'roxi/xpath'
require 'roxi/xquery/xquery'
