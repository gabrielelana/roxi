module ROXI::XPath::NodePattern

  class Node

    def match(context)
      true
    end

  end

  class Text

    def initialize(pattern=nil)
      @pattern = pattern
    end

    def match(context)
      return false if not context.node.instance_of? ROXI::XText
      return false if (not @pattern.nil?) and
        (not ::Regexp.new(@pattern).match(context.node.value))
      return true
    end

  end

  class Comment

    def initialize(pattern=nil)
      @pattern = pattern
    end

    def match(context)
      return false if not context.node.instance_of? ROXI::XComment
      return false if (not @pattern.nil?) and
        (not ::Regexp.new(@pattern).match(context.node.value))
      return true
    end

  end

  class ProcessingInstruction

    def initialize(processor=nil)
      @processor = processor
    end

    def match(context)
      return false if not context.node.instance_of? ROXI::XInstruction
      return false if (not @processor.nil?) and
        (not @processor == context.node.processor)
      return true
    end

  end

  class All

    def match(context)
      if context.axis == ROXI::XPath::Axis::Attribute
        return true if context.node.instance_of? ROXI::XAttribute
        return false
      elsif context.axis == ROXI::XPath::Axis::Namespace
        return true if context.node.instance_of? ROXI::XNamespace
        return false
      else
        return true if (context.node.instance_of? ROXI::XElement)
        return false
      end
    end

  end

  class Name < All

    def initialize(name, prefix=nil)
      @name = name
      @prefix = prefix
    end

    def match(context)
      return false if not super
      match_name(context) and match_namespace(context)
    end

    def match_name(context)
      return false if not context.node.respond_to? :name
      context.node.name == @name
    end

    def match_namespace(context)
      return false if not context.node.respond_to? :namespace
      context.node.namespace == resolve_namespace(context)
    end

    def resolve_namespace(context)
      return nil if @prefix.nil?
      raise "prefix #{@prefix} not defined in context" if
        not context.namespaces.key?(@prefix)
      context.namespaces[@prefix]
    end

  end

  class Prefix < Name
    
    def initialize(prefix)
      @prefix = prefix
    end

    def match(context)
      return false if context.node.instance_of? ROXI::XNamespace
      return super
    end

    def match_name(context)
      true
    end

  end

  class Pattern < Name

    def match_name(context)
      return false if not context.node.respond_to? :name
      ::Regexp.new(@name).match(context.node.name)
    end

  end

end
