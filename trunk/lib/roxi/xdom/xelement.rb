require 'forwardable'

module ROXI

  class XElement < XChild
    include Enumerable
    include XContainer
    extend Forwardable

    attr_reader :namespaces
    def_delegators :@name, :name, :prefix, :local_name, :qualified_name
    def_delegators :@name, :name=, :prefix=, :local_name=

    def initialize(name, *args)
      super()
      @children = []
      @attributes = []
      @namespaces = []
      @name = name.instance_of?(XName) ? name : XName.parse(name)
      args.each { | node | append(node) }
    end

    def clone
      nodes = []
      @attributes.each { | node | nodes << node.clone }
      @namespaces.each { | node | nodes << node.clone }
      @children.each { | node | nodes << node.clone }
      XElement.new(qualified_name, *nodes)
    end

    def each(&block)
      @namespaces.each { | namespace | yield namespace }
      @attributes.each { | attribute | yield attribute }
      super
    end

    def id
      id = @attributes.find { | attribute | attribute.instance_of? XIdAttribute }
      return id.value if not id.nil?
    end

    def lang
      lang = @attributes.find { | attribute | attribute.instance_of? XLangAttribute }
      return lang.value if not lang.nil?
      @parent.lang if not @parent.nil?
    end

    def url(relative='')
      url = @attributes.find { | attribute | attribute.instance_of? XBaseAttribute }
      return url.resolve(relative) if not url.nil?
      @parent.url if not @parent.nil?
    end

    def value
      @children.inject('') { | value, child | value << child.value }
    end

    def namespace(name=prefix)
      namespace = @namespaces.find { | namespace | namespace.name == name }
      return namespace.value if not namespace.nil?
      if not @parent.nil?
        if @parent.respond_to?(:namespace)
          then @parent.namespace(name)
          else nil
        end
      end
    end

    private

    def insert_node(index, node)
      begin
        node = node.clone if not node.parent.nil?
        container_for_node(node).insert(index, node)
        node.parent = self
      rescue
        insert_object(index, node)
      end
    end

    def insert_object(index, object)
      case object
      when Array
        object.flatten.inject(index) do | index, node |
          insert_node(index, node)
          if index < 0 then index else index.succ end
        end
      else
        insert_node(index, XText.new(object.to_s))
      end
    end

    def container_for_node(node)
      if node.kind_of? XAttribute
        @attributes
      elsif node.kind_of? XNamespace
        @namespaces
      elsif node.kind_of? XChild
        @children
      else
        raise
      end
    end

    protected

    def path_name
      '/' + qualified_name
    end

  end

end
