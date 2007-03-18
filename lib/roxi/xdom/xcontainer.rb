
module ROXI

  module XContainer

    def children(name=nil)
      all_nodes_with_name(name, @children)
    end

    def children?(name=nil)
      !children(name).empty?
    end

    def child(name=nil)
      node_with_name(name, @children)
    end

    def child?(name=nil)
      begin; child(name); rescue; false; else; true; end
    end

    def attributes(name=nil)
      all_nodes_with_name(name, @attributes)
    end

    def attributes?(name=nil)
      !attributes(name).empty?
    end

    def attribute(name=nil)
      node_with_name(name, @attributes)
    end

    def attribute?(name=nil)
      begin; attribute(name); rescue; false; else; true; end
    end

    def text
      @children.select { | child | child.instance_of? XText }
    end

    def position(node)
      container_for_node(node).index(node) + 1
    end

    def following_sibling(node)
      assert_member node, @children
      return [] if @children.last == node
      @children[@children.index(node)+1..-1]
    end

    def preceding_sibling(node)
      assert_member node, @children
      return [] if @children.first == node
      @children[0..@children.index(node)-1]
    end

    def each(&block)
      @children.each do | child |
        yield child
        if child.kind_of? Enumerable
          child.each(&block)
        end
      end
    end

    def append(node)
      insert_node(-1, node)
      self
    end

    def insert_node_before(before, node)
      assert_member node, container_for_node(node)
      insert_node(container_for_node(node).index(node), before)
      self
    end

    def insert_node_after(after, node)
      assert_member node, container_for_node(node)
      insert_node(container_for_node(node).index(node).succ, after)
      self
    end

    def replace_node(node, replace)
      assert_same_container node, replace
      index = container_for_node(node).index(node)
      delete_node(node)
      insert_node(index, replace)
      self
    end

    def delete_node(node)
      assert_member node, container_for_node(node)
      container_for_node(node).delete(node)
      node.parent = nil
      self
    end

    alias_method :<<, :append
    alias_method :add, :append

    private

    def assert_member(node, collection)
      if not collection.include?(node)
        raise 'node is not member of collection'
      end
    end

    def assert_same_container(left, right)
      if not container_for_node(left) ==
        container_for_node(right)
        raise 'nodes is not in the same collection'
      end
    end
    
    def all_nodes_with_name(name, collection)
      return collection if name.nil?
      collection.select do | node |
        node.respond_to? :qualified_name and
        name === node.qualified_name
      end
    end
    
    def node_with_name(name, collection)
      begin
        all_nodes_with_name(name, collection).only
      rescue
        raise "not only one node with name #{name}"
      end
    end

  end

end
