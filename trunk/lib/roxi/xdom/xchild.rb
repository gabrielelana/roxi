
module ROXI

  class XChild < XNode

    def initialize
      super()
    end

    def wrap(wrapper)
      @parent.replace_node(self, wrapper) if not @parent.nil?
      wrapper.append(self)
      self
    end

    def insert_before(child)
      @parent.insert_node_before(child, self) if not @parent.nil? 
      self
    end

    def insert_after(child)
      @parent.insert_node_after(child, self) if not @parent.nil? 
      self
    end

    def path
      return super if @parent.nil?
      super + '[' + @parent.position(self).to_s + ']'
    end

  end

end
