module ROXI::XPath::Axis

  class Attribute

    def Attribute.walk(nodes)
      nodes.inject([]) do | attributes, node |
        next attributes if not node.respond_to? :attributes
        attributes.concat(node.attributes)
      end
    end

  end

  class Namespace

    def Namespace.walk(nodes)
      AncestorOrSelf.walk(nodes).inject([]) do | namespaces, node |
        next namespaces if not node.respond_to? :namespaces
        namespaces.concat(node.namespaces)
      end
    end
    
  end

  class Child

    def Child.walk(nodes)
      nodes.inject([]) do | children, node |
        next children if not node.respond_to? :children
        children.concat(node.children)
      end.uniq
    end

  end

  class Descendant

    def Descendant.walk(nodes)
      nodes.inject([]) do | nodes, node |
        nodes.concat(Descendant.node(node))
      end.uniq
    end

    def Descendant.node(node)
      return [] if not node.respond_to? :children
      node.children.inject([]) do | nodes, child |
        nodes.push(child)
        nodes.concat(Descendant.node(child))
      end
    end

  end

  class DescendantOrSelf < Descendant

    def DescendantOrSelf.walk(nodes, descendant=[])
      nodes.inject([]) do | nodes, node |
        nodes.push(node)
        nodes.concat(Descendant.node(node))
      end.uniq
    end

  end

  class Self

    def Self.walk(nodes)
      nodes
    end

  end

  class Parent

    def Parent.walk(nodes)
      nodes.inject([]) do | parents, node |
        next parents if node.parent.nil?
        parents.push(node.parent)
      end.uniq
    end

  end

  class Ancestor

    def Ancestor.walk(nodes)
      nodes.inject([]) do | nodes, node |
        nodes.concat(Ancestor.node(node))
      end.uniq
    end

    def Ancestor.node(node, ancestors=[])
      return [] if node.parent.nil?
      ancestors.push(node.parent)
      ancestors.concat(Ancestor.node(node.parent))
    end
    
  end

  class AncestorOrSelf

    def AncestorOrSelf.walk(nodes)
      nodes.inject([]) do | ancestors, node |
        ancestors.push(node)
        ancestors.concat(Ancestor.node(node))
      end.uniq
    end

  end

  class FollowingSibling
    
    def FollowingSibling.walk(nodes)
      nodes.inject([]) do | siblings, node |
        next siblings if node.parent.nil?
        siblings.concat(node.parent.following_sibling(node))
      end.uniq
    end

  end

  class PrecedingSibling
    
    def PrecedingSibling.walk(nodes)
      nodes.inject([]) do | siblings, node |
        next siblings if node.parent.nil?
        siblings.concat(node.parent.preceding_sibling(node).reverse)
      end.uniq
    end
    
  end

  class Following

    def Following.walk(nodes)
      nodes.inject([]) do | following, node |
        next following if node.parent.nil?
        Ancestor.node(node).each do | ancestor |
          ancestor.following_sibling(node).each do | sibling |
            following.push(sibling)
            following.concat(Descendant.node(sibling))
          end
          node = ancestor
        end
        following
      end.uniq
    end

  end

  class Preceding

    def Preceding.walk(nodes)
      nodes.inject([]) do | preceding, node |
        next preceding if node.parent.nil?
        Ancestor.node(node).each do | ancestor |
          ancestor.preceding_sibling(node).reverse.each do | sibling |
            preceding.concat(Descendant.node(sibling).reverse)
            preceding.push(sibling)
          end
          node = ancestor
        end
        preceding
      end.uniq
    end
  end

end
