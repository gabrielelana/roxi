
module ROXI

  class Writer

    def initialize(root)
      @root = root
    end

    def write(node, out, level=0)
      case node
      when XDocument: write_document(node, out, level)
      when XDeclaration: write_declaration(node, out, level)
      when XElement: write_element(node, out, level)
      when XAttribute: write_attribute(node, out, level)
      when XNamespace: write_namespace(node, out, level)
      when XComment: write_comment(node, out, level)
      when XCData: write_cdata(node, out, level)
      when XInstruction: write_instruction(node, out, level)
      when XText: write_text(node, out, level)
      end
    end

    def write_document(node, out, level=0)
      write(node.declaration, out, level)
      node.children.each { | c | write(c, out, level) }
    end

    def write_declaration(node, out, level=0)
      out << '<?xml ' + node.value + '?>' + "\n"
    end

    def write_element(node, out, level=0)
      out << "\t"*level + '<' + node.qualified_name + ' '
      node.namespaces.each { | n | write(n, out, level) }
      node.attributes.each { | a | write(a, out, level) }
      if node.children.empty?
        out << '/>' << "\n"
      else
        out.rstrip!
        out << '>' << "\n"
        node.children.each do | c | 
          write(c, out, level+1)
        end
        out << "\t"*level + '</' + node.qualified_name + '>' << "\n"
      end
    end

    def write_instruction(node, out, level=0)
      out << "\t" * level + '<?' + node.processor + ' ' + node.value + '?>' + "\n"
    end

    def write_comment(node, out, level=0)
      out << "\t" * level + '<!-- ' + node.value + ' -->' + "\n"
    end

    def write_cdata(node, out, level=0)
      out << "\t" * level + '<![CDATA[ ' + node.value + ' ]]>' + "\n"
    end

    def write_text(node, out, level=0)
      out << "\t" * level + node.value.sub(/\n/, "\n" + "\t" * level) << "\n"
    end
    
    def write_attribute(node, out, level=0)
      out << node.qualified_name + '="' + node.value + '" '
    end
    
    def write_namespace(node, out, level=0)
      xmlns = node.name.empty? ? 'xmlns' : 'xmlns:'
      out << xmlns + node.name + '="' + node.url + '" '
    end

    def pretty
      out = ''
      write(@root, out)
      out
    end

  end

end
