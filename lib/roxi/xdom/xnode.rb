
module ROXI

  module XValue

    def to_i
      if (i = value.to_i).to_s != value.to_s
        raise "\"#{value}\" is not interpretable as integer"
      end
      i
    end

    def to_f
      if (f = value.to_f).to_s != value.to_s
        raise "\"#{value}\" is not interpretable as float"
      end
      f
    end

    def to_n
      return value.to_i if value.to_i.to_s == value.to_s
      return value.to_f if value.to_f != 0.0
      return value.to_f if value.to_s =~ /0?\.0+/
      raise "\"#{value}\" is not interpretable as number"
    end

    def to_b
      return true if value == 'true' or value == 'yes' or value == '1'
      return false if value == 'false' or value == 'no' or value == '0'
      raise "\"#{value}\" is not interpretable as boolean"
    end

  end


  class XItem

    attr_reader :parent, :value

    def initialize
      @parent = nil
    end

    def lang
      return '' if @parent.nil?
      @parent.lang
    end

    def path
      return path_name if @parent.nil?
      @parent.path + path_name
    end

    def order
      return order_default if @parent.nil?
      @parent.order + order_separator + @parent.position(self).to_s
    end

    def document
      return self if @parent.nil?
      @parent.document
    end

    def <=>(other)
      raise "#{other.class} is not comparable to #{self.class}" if not other.respond_to? :order
      order <=> other.order
    end

    def to_s
      Writer.new(self).pretty
    end

    protected

    def parent=(parent)
      @parent = parent
    end

    def order_separator
      '.'
    end

    def order_default
      '1'
    end

  end


  class XNode < XItem

    include XValue

    def initialize
      super()
      @value = ''
    end

    def delete
      @parent.delete_node(self) if not @parent.nil?
      self
    end

    def replace(node)
      @parent.replace_node(self, node) if not @parent.nil?
      self
    end

  end

end
