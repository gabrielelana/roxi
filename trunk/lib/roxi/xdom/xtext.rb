
module ROXI

  class XCData < XChild

    attr_accessor :value

    def initialize(value)
      raise ']]> invalid token in XCData' if value =~ /\]\]>/
      @value = value
    end

  end

  class XText < XChild
    
    attr_accessor :value

    def initialize(value)
      super()
      @value = value
    end

    def clone
      XText.new(@value)
    end

    protected
    def path_name
      '/text()'
    end

  end

end
