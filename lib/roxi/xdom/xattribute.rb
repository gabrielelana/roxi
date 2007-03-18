require 'forwardable'

module ROXI

  class XAttribute < XNode
    extend Forwardable

    attr_writer :value
    def_delegators :@name, :name, :prefix, :local_name, :qualified_name
    def_delegators :@name, :name=, :prefix=, :local_name=

    def initialize(name, value)
      super()
      @name = name.instance_of?(XName) ? name : XName.parse(name)
      @value = value.to_s
    end

    def namespace
      @parent.namespace(prefix) if not prefix.empty?
    end

    def clone
      XAttribute.new(qualified_name, @value)
    end

    protected

    def path_name
      '/@' + qualified_name
    end

    def order_separator
      '%'
    end

  end


  class XIdAttribute < XAttribute

    def initialize(value)
      super('xml:id', value)
    end

  end


  class XLangAttribute < XAttribute

    def initialize(value)
      super('xml:lang', value)
    end

  end


  class XBaseAttribute < XAttribute

    def initialize(value)
      super('xml:base', value)
    end

    def resolve(url)
      return @value if url == ''
      @value + url
    end

  end

end
