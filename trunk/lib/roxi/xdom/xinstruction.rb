
module ROXI

  class XInstruction < XChild

    attr_accessor :processor, :value

    def initialize(processor, value)
      super()
      @processor = processor
      @value = value
    end

    def clone
      XInstruction.new(@processor, @value)
    end

    protected
    def path_name
      '/process-instruction(' + @processor + ')'
    end

  end

end
