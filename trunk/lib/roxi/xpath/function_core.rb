module ROXI::XPath::Function

  class Boolean

    def Boolean.eval(context, value)
      if value.instance_of? TrueClass or
        value.instance_of? FalseClass
        return value
      elsif value.instance_of? Array or
        value.instance_of? ::String
        return !value.empty?
      elsif value.instance_of? Float
        return false if value.zero?
        return false if value.nan?
        return true
      elsif value.kind_of? ROXI::XValue
        return value.to_b
      else
        raise "unable to evaluate '#{value}:#{value.class}' as boolean"
      end
    end

  end

  class String

    def String.eval(context, value)
      if value.instance_of? ::String
        return value
      elsif value.instance_of? TrueClass or
        value.instance_of? FalseClass
        return value.to_s
      elsif value.instance_of? Float
        return value.to_s if value.nan? or value.infinite? or value.floor != value
        return sprintf('%.0f', value)
      elsif value.instance_of? Array
        return String.eval(context, value.first) if not value.empty?
        return ''
      elsif value.kind_of? ROXI::XValue
        return value.value.to_s
      else
        raise "unable to evaluate '#{value}:#{value.class}' as string"
      end
    end

  end

  class Number

    def Number.eval(context, value)
      if value.instance_of? Float
        return value
      elsif value.kind_of? Numeric
        return value.to_f
      elsif value.instance_of? ::String
        return value.to_i.to_f if value.to_i.to_s == value.to_s
        return value.to_f if value.to_f.to_s == value.to_s
        return value.to_f if value.to_s =~ /0?\.0+/
        return ROXI::XPath::NaN
      elsif value.instance_of? Array
        return Number.eval(context, value.first) if not value.empty?
        return ''
      elsif value.instance_of? TrueClass
        return 1.0
      elsif value.instance_of? FalseClass
        return 0.0
      elsif value.kind_of? ROXI::XValue
        return Number.eval(context, value.value)
      else
        raise "unable to evaluate '#{value}:#{value.class}' as numeric"
      end
    end

  end

  class NodeSet

    def NodeSet.eval(context, value)
      if not value.instance_of? Array
        raise "unable to evaluate '#{value}:#{value.class}' as nodeset"
      end
      value
    end

  end

  class Ceiling

    def Ceiling.eval(context, value)
      begin
        Number.eval(context, value).ceil
      rescue
        value
      end
    end

  end

  class Concat

    def Concat.eval(context, *values)
      values.inject('') do | total, value |
        total.concat(String.eval(context, value))
      end
    end

  end

  class Contains

    # NOTE: over standard
    def Contains.eval(context, lvalue, rvalue)
      String.eval(context, lvalue).match(
        String.eval(context, rvalue)) != nil
    end

  end

  class Count

    def Count.eval(context, nodes)
      NodeSet.eval(context, nodes).size
    end

  end

  class False

    def False.eval(context)
      false
    end

  end

  class Floor

    def Floor.eval(context, value)
      begin
        Number.eval(context, value).floor
      rescue
        value
      end
    end

  end

  class Id
    include ROXI

    def Id.eval(context, value)
      return Id.context_node(context) if value.nil?
      return Id.with_strings(context, value.split(/\s+/)) if value.instance_of? ::String 
      return Id.with_strings(context, Strings.eval(context, value)) if value.instance_of? ::Array
      Id.with_strings(context, [String.eval(context, value)])
    end

    # NOTE: over standard
    def Id.context_node(context)
      if (id = context.node.id).nil? then '' else id end
    end

    def Id.with_strings(context, strings)
      strings.inject([]) do | nodes, id |
        nodes.concat(
          context.document.find_all do | node |
            node.id == id if node.kind_of? XContainer
          end
        ).uniq
      end
    end

  end

  class Lang

    def Lang.eval(context, value)
      return false if context.node.lang.nil?
      StartsWith.eval(context, context.node.lang, String.eval(context, value))
    end

  end

  class Last

    def Last.eval(context)
      context.nodes.size
    end

  end
      
  class LocalName

    def LocalName.eval(context, value)
      Private::NameFunction.eval(context, value, :local_name)
    end

  end

  class Name

    def Name.eval(context, value)
      Private::NameFunction.eval(context, value, :qualified_name)
    end

  end

  class NamespaceUri

    def NamespaceUri.eval(context, value)
      (namespace = Private::NameFunction.eval(context, value, :namespace)) ? namespace : ''
    end

  end

  class NormalizeSpace
    
    def NormalizeSpace.eval(context, value)
      value = context.node if value.nil?
      value = String.eval(context, value)
      value.strip.gsub(/\s+/um, ' ')
    end

  end

  class Not
    
    def Not.eval(context, value)
      !Boolean.eval(context, value)
    end

  end

  class Position

    def Position.eval(context)
      context.position
    end

  end

  class Round

    def Round.eval(context, value)
      begin
        Number.eval(context, value).round
      rescue
        value
      end
    end

  end

  class StartsWith

    def StartsWith.eval(context, lvalue, rvalue)
      String.eval(context, lvalue).index(
        String.eval(context, rvalue)
      ) == 0
    end

  end

  class EndsWith

    def EndsWith.eval(context, lvalue, rvalue)
      lvalue = String.eval(context, lvalue)
      rvalue = String.eval(context, rvalue)
      lvalue.rindex(rvalue) == (lvalue.length - rvalue.length)
    end

  end

  class StringLength

    def StringLength.eval(context, value)
      value = context.node if value.nil?
      String.eval(context, value).length
    end

  end

  class Substring

    def Substring.eval(context, *values)
      string, start, length = *values

      string = String.eval(context, string)
      start = Number.eval(context, start)
      length = if length.nil?
        then ROXI::XPath::InfP
        else Number.eval(context, length)
      end
      stop = start + length
      
      begin
        start = Substring.deal_with_float(context, start)
        stop = Substring.deal_with_float(context, stop)

        string_length = string.length
        start = (1..string_length+1).clip(start)
        stop = (1..string_length+1).clip(stop)

        string[start-1,stop-1]
      rescue
        return ''
      end
    end

    private

    def Substring.deal_with_float(context, float)
      if float.instance_of? Float
        return float if float.infinite?
        raise if float.nan?
        float = Round.eval(context, float)
      end
      float
    end

  end

  class SubstringAfter
    
    def SubstringAfter.eval(context, lvalue, rvalue)
      lvalue = String.eval(context, lvalue)
      rvalue = String.eval(context, rvalue)
   
      return '' if not lvalue.include?(rvalue)
      lvalue[lvalue.index(rvalue)+rvalue.length..-1]
    end

  end

  class SubstringBefore
    
    def SubstringBefore.eval(context, lvalue, rvalue)
      lvalue = String.eval(context, lvalue)
      rvalue = String.eval(context, rvalue)
   
      return '' if not lvalue.include?(rvalue)
      return '' if lvalue.index(rvalue) == 0
      lvalue[0..lvalue.index(rvalue)-1]
    end

  end

  class Sum

    def Sum.eval(context, nodes)
      nodes = NodeSet.eval(context, nodes)
      nodes.inject(0) do | total, node |
        total += Number.eval(context, node)
      end
    end

  end

  class Translate
    
    def Translate.eval(context, *values)
      values.collect! do | value |
        String.eval(context, value)
      end
      string, from, to = values

      map = Hash.new
      (0...from.length).each do | pos |
        map[from[pos,1]] = to[pos,1]
      end

      string.split('').inject('') do | string, char |
        string << if map.has_key? char then map[char] else char end
      end
    end

  end

  class True

    def True.eval(context)
      true
    end

  end


  module Private

    module NameFunction

      def NameFunction.eval(context, value, query)
        value = [context.node] if value.nil?
        nodes = NodeSet.eval(context, value)
        return '' if nodes.empty?
        return '' if not nodes.first.respond_to? query
        nodes.first.send(query)
      end

    end

  end

end
