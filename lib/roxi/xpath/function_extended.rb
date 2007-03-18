module ROXI::XPath::Function

  class Mul

    def Mul.eval(context, lvalue, rvalue)
      lnodes = NodeSet.eval(context, lvalue)
      rnodes = NodeSet.eval(context, rvalue)
      raise 'cannot multiply different size vectors' if lnodes.size != rnodes.size
      (0...lnodes.size).inject([]) do | total, index |
        total << (Number.eval(context, lnodes[index]) * Number.eval(context, rnodes[index]))
      end
    end

  end

  class Min

    def Min.eval(context, value)
      begin
        Numbers.eval(context, value).min
      rescue
        ROXI::XPath::NaN
      end
    end

  end

  class Max

    def Max.eval(context, value)
      begin
        Numbers.eval(context, value).max
      rescue
        ROXI::XPath::NaN
      end
    end

  end

  class Avg

    def Avg.eval(context, value)
      nodes = NodeSet.eval(context, value)
      return 0.0 if nodes.empty?
      Sum.eval(context, nodes)/nodes.size
    end

  end

  class ExtensionAdapter

    def ExtensionAdapter.eval(context, name, *args)
      if not context.functions.key?(name)
        raise "undefined function #{name} in context"
      end
      context.functions[name].call(context, *args)
    end

  end

  class SortInDocumentOrder

    def SortInDocumentOrder.eval(context, value)
      NodeSet.eval(context, value).sort
    end

  end

  class SortInReverseDocumentOrder

    def SortInReverseDocumentOrder.eval(context, value)
      SortInDocumentOrder.eval(context, value).reverse
    end

  end

  class DistinctValues

    def DistinctValues.eval(context, value)
      Values.eval(context, value).uniq
    end

  end

  class Values

    def Values.eval(context, value)
      NodeSet.eval(context, value).collect do | node |
        String.eval(context, node)
      end
    end

  end

  class Numbers

    def Numbers.eval(context, value)
      NodeSet.eval(context, value).collect do | node |
        Number.eval(context, node)
      end
    end

  end

  class Strings

    def Strings.eval(context, value)
      NodeSet.eval(context, value).collect do | node |
        String.eval(context, node)
      end
    end

  end

  class Booleans

    def Booleans.eval(context, value)
      NodeSet.eval(context, value).collect do | node |
        Boolean.eval(context, node)
      end
    end

  end

  class Dates
    
    def Dates.eval(context, value)
      NodeSet.eval(context, value).collect do | node |
        Date.parse(String.eval(context, node))
      end
    end

  end

  class Only

    def Only.eval(context, value)
      value.only
    end

  end

  class First

    def First.eval(context, value)
      value.first
    end

  end
 
end
