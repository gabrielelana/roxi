
module ROXI::XUpdate

  def self.update(node, &block)
    instance = DSLInterpreter.new(node)
    instance.instance_eval(&block)
  end

  class DSLInterpreter

    private

    def initialize(node)
      @node = node
    end

    def select(query, &block)
      @node.xpath(query).each { | item | block.call(item) }
      @node
    end

    def remove(query)
      @node.xpath(query).each { | item | item.delete }
      @node
    end

  end

end
