
module ROXI

  class XComment < XChild

    attr_writer :value

    def initialize(value)
      super()
      @value = value
    end

    def clone
      XComment.new(@value)
    end

    protected
    def path_name
      '/comment()'
    end

  end

end
