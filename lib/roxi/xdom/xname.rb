module ROXI

  class XName

    attr_accessor :name, :prefix
    alias_method :local_name, :name
    alias_method :local_name=, :name=
    
    def initialize(prefix, name)
      @prefix = prefix
      @name = name
    end

    def qualified_name
      return @name if @prefix.empty?
      @prefix + ':' + @name
    end

    def XName.parse(string)
      tokens = string.split(':')
      return XName.new(*tokens) if tokens.size == 2
      XName.new('', tokens.first)
    end

  end

end
