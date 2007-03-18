
module ROXI::XQuery

  def self.from(*args, &block)
    instance = DSLInterpreter.new(Array.cartesian(*args))
    instance.instance_eval(&block).flatten
  end

  class DSLInterpreter

    private
    def initialize(nodeset)
      @nodeset = nodeset
    end

    def where(&block)
      @nodeset = @nodeset.select do | element |
        block.call(*element)
      end
    end

    def order_by(order=:ascending, &block)
      @nodeset = @nodeset.sort_by do | element |
        block.call(*element)
      end
      @nodeset.reverse! if order == :descending
      @nodeset
    end

    def select(&block)
      @nodeset = @nodeset.collect do | element |
        block.call(*element)
      end
    end

    def group_by(&block)
      @nodeset = block.call(*(@nodeset.transpose))
    end

    def filter(&block)
      @nodeset = block.call(@nodeset)
    end

  end

end
