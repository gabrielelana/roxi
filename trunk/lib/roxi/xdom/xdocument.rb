
module ROXI
  
  class XDocument < XItem
    include XContainer
    include Enumerable

    attr_accessor :declaration

    def initialize(*args)
      super()
      @root = nil
      @children = []
      @attributes = []
      @declaration = XDeclaration.new
      args.each do | node |
        if node.instance_of? XDeclaration
          @declaration = node
        else
          append(node)
        end
      end
    end

    def clone
      nodes = []
      @attributes.each { | node | nodes << node.clone }
      @children.each { | node | nodes << node.clone }
      XDocument.new(@declaration.clone, *nodes)
    end

    def delete_node(node)
      super(node)
      @root = nil if @root = node
      self
    end
    
    private

    def insert_node(index, node)
      assert_one_root(node)
      node = node.clone if not node.parent.nil?
      container_for_node(node).insert(index, node)
      node.parent = self
    end

    def container_for_node(node)
      case node
      when XElement, XComment, XInstruction
        @children
      else
        raise "#{node.class} could not be added to ROXI::XDocument"
      end
    end

    def assert_one_root(node)
      if node.instance_of? XElement
        if not @root.nil?
          raise 'only one ROXI::XElement could be added to ROXI::XDocument'
        end
        @root = node
      end
    end

    protected

    def path_name
      ''
    end

  end

end
