require 'roxi'

require 'roxi/xpath/context'
require 'roxi/xpath/axis'
require 'roxi/xpath/pattern'
require 'roxi/xpath/expression'
require 'roxi/xpath/operator'
require 'roxi/xpath/function_core'
require 'roxi/xpath/function_extended'
require 'roxi/xpath/parser'
require 'roxi/xpath/builder'
require 'roxi/xpath/optimizer'

module ROXI::XPath

  NaN = 0.0/0.0
  InfP = 1.0/0.0
  InfN = -1.0/0.0

  def self.from(node, document=nil)
    context = ROXI::XPath::Context.new
    context.node = node
    context.document = document(node, document)
    Evaluator.new(context)
  end

  def self.document(node, document)
    return document if not document.nil?
    if node.instance_of? Array
      node.first.document
    else
      node.document
    end
  end

  class Evaluator

    def initialize(context)
      @context = context
    end

    def eval(expression, context=@context)
      ROXI::XPath::Builder.new(
        ROXI::XPath::Optimizer.optimize(expression)).
          build.eval(context)
    end

  end

end

module ROXI::XContainer

  def xpath(expression, context=nil)
    context ||= ROXI::XPath::Context.new
    context.node = self
    context.document = self.document
    ROXI::XPath::Builder.new(
      ROXI::XPath::Optimizer.optimize(expression)).
        build.eval(context)
  end

end

module ROXI::XBind
  def xattribute(bindings)
    module_eval %{
      def initialize(dom)
        @dom = dom
      end
    }
    bindings.each do | attribute, path |
      module_eval %{
        def #{attribute}
          @dom.xpath('#{path}')
        end
      }
    end
  end
end
