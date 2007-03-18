module ROXI::XPath

  class Context
    attr_accessor :axis
    attr_accessor :node
    attr_accessor :nodes
    attr_accessor :document
    attr_accessor :namespaces
    attr_accessor :variables
    attr_accessor :functions

    def initialize
      @axis = nil
      @node = nil
      @nodes = []
      @document = nil
      @namespaces = {}
      @variables = {}
      @functions = {}
    end

    def position
      @nodes.index(@node) + 1
    end

    def clone
      context = Context.new
      context.axis = @axis
      context.node = @node
      context.nodes = @nodes
      context.document = @document
      context.namespaces = @namespaces
      context.variables = @variables
      context.functions = @functions
      context
    end

    def self.copy(context)
      copy = Context.new
      copy.axis = context.axis
      copy.node = context.node
      copy.nodes = context.nodes
      copy.document = context.document
      copy.namespaces = context.namespaces
      copy.variables = context.variables
      copy.functions = context.functions
      copy
    end
    
  end

end
