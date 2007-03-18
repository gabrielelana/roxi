
module ROXI

  class XNamespace < XNode

    attr_accessor :name, :url
    alias_method :value, :url
    alias_method :value=, :url=

    def initialize(name, url)
      super()
      @name = name
      @url = url
    end

    def clone
      XNamespace.new(@name, @url)
    end

    protected

    def path_name
      '/namespace(' + name + ')'
    end

    def order_separator
      '#'
    end

  end

end
