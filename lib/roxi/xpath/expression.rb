module ROXI::XPath::Expression

  class Literal

    def initialize(value)
      @value = value
    end

    def eval(context)
      @value
    end

  end


  class Variable

    def initialize(name)
      @name = name
    end

    def eval(context)
      catch(:found) do
        search_in_context(context)
        search_in_global_scope
        raise "undefined variable #{@name} in context"
      end
    end

    def search_in_context(context)
      throw(:found, context.variables[@name]) if
        context.variables.key?(@name)
    end

    def search_in_global_scope
      throw(:found, Kernel.eval("$#{@name}")) if
        global_variables.include?("$#{@name}")
    end

  end


  class Expression
  
    def initialize(*expressions)
      @expressions = expressions
    end

    def eval(context)
      self.class.eval(context,
        *@expressions.inject([]) do | values, expression |
          values << expression.eval(context)
        end
      )
    end

    def Expression.eval(context, *values)
      return values if values.size > 1
      values.first
    end

  end


  class Function
  
    def initialize(name, expressions=[])
      @name = name
      @expressions = expressions
    end

    def eval(context)
      Function.eval(context, @name,
        @expressions.inject([]) do | values, expression |
          values << expression.eval(context)
        end
      )
    end

    def Function.eval(context, name, arguments)
      begin
        Function.function_class(name).eval(context, *arguments)
      rescue NameError
        ROXI::XPath::Function::ExtensionAdapter.eval(context, name, *arguments)
      end
    end

    def Function.function_class(function_name)
      Module.const_get_deep(internal_function_name(function_name).to_sym)
    end

    def Function.internal_function_name(function_name)
      prefix = 'ROXI::XPath::Function::'
      function_name.split('-').inject(prefix) do | name, token |
        name.concat(token.capitalize)
      end
    end

  end


  class LocationStep

    def initialize(axis, pattern, predicates=[])
      @axis = axis
      @pattern = pattern
      @predicates = predicates
    end

    def eval(context)
      eval_axis(context)
      eval_pattern(context)
      eval_predicates(context)
    end

    def eval_axis(context)
      context.axis = @axis
      context.nodes = @axis.walk(context.nodes)
    end

    def eval_pattern(context)
      context.nodes = context.nodes.select do | node |
        context.node = node
        @pattern.match(context)
      end
    end

    def eval_predicates(context)
      return true if @predicates.empty?
      context.nodes = context.nodes.select do | node |
        context.node = node
        @predicates.all? do | predicate |
          predicate.eval(context)
        end
      end
    end

  end


  class Predicate

    def initialize(expression)
      @expression = expression
    end

    def eval(context)
      as_boolean(context, @expression.eval(context))
    end

    def as_boolean(context, value)
      return value == context.position if value.kind_of? Numeric
      ROXI::XPath::Function::Boolean.eval(context, value)
    end

  end


  class LocationPath

    def initialize(location_steps)
      @location_steps = location_steps
    end

    def eval(context)
      context = context.clone
      context.nodes = context_nodes(context)
      @location_steps.each do | location_step |
        location_step.eval(context)
      end
      context.nodes
    end

  end


  class RelativeLocationPath < LocationPath

    def context_nodes(context)
      [ context.node ].flatten
    end

  end


  class AbsoluteLocationPath < LocationPath

    def context_nodes(context)
      [ context.document ]
    end

  end


  class Filter

    def initialize(expression, predicates=[], location_path=nil)
      @expression = expression
      @predicates = predicates
      @location_path = location_path
    end

    def eval(context)
      context = context.clone
      eval_expression(context)
      eval_predicates(context)
      eval_location_path(context)
      context.nodes
    end

    def eval_expression(context)
      context.nodes = @expression.eval(context)
    end

    def eval_predicates(context)
      return true if @predicates.empty?
      context.nodes = context.nodes.select do | node |
        context.node = node
        @predicates.all? do | predicate |
          predicate.eval(context)
        end
      end
    end

    def eval_location_path(context)
      if not @location_path.nil?
        context.node = context.nodes
        context.nodes = @location_path.eval(context)
      end
    end

  end


  class Equality

    def initialize(lexpression, rexpression, operator)
      @lexpression = lexpression
      @rexpression = rexpression
      @operator = operator
    end

    def eval(context)
      Equality.eval(
        @lexpression.eval(context),
        @rexpression.eval(context),
        @operator)
    end

    def Equality.eval_nodes_vs_number(nodes, value, operator)
      if value.kind_of? Numeric
        throw(:done,
          nodes.any? do | node |
            node.to_n.send(operator, value)
          end
        )
      end
    end

    def Equality.eval_nodes_vs_string(nodes, value, operator)
      if value.instance_of? String
        throw(:done,
          nodes.any? do | node |
            node.value.to_s.send(operator, value.to_s)
          end
        )
      end
    end

    def Equality.eval_nodes_vs_boolean(nodes, value, operator)
      if value.instance_of? TrueClass or value.instance_of? FalseClass
        throw(:done,
          ROXI::XPath::Function::Boolean.eval(nil, nodes).send(
            operator, value
          )
        )
      end
    end

    def Equality.nodes_as_lvalue(lvalue, rvalue)
      if lvalue.instance_of? Array
        nodes = lvalue
        value = rvalue
      else
        nodes = rvalue
        value = lvalue
      end
      return [ nodes, value ]
    end

    def Equality.eval_boolean_vs_value(lvalue, rvalue, operator)
      if lvalue.instance_of? TrueClass or lvalue.instance_of? FalseClass or
        rvalue.instance_of? TrueClass or rvalue.instance_of? FalseClass
        throw(:done,
          ROXI::XPath::Function::Boolean.eval(nil, lvalue).send(
            operator, ROXI::XPath::Function::Boolean.eval(nil, rvalue)
          )
        )
      end
    end

    def Equality.eval_numeric_vs_value(lvalue, rvalue, operator)
      if lvalue.kind_of? Numeric or rvalue.kind_of? Numeric
        throw(:done,
          ROXI::XPath::Function::Number.eval(nil, lvalue).send(
            operator, ROXI::XPath::Function::Number.eval(nil, rvalue)
          )
        )
      end
    end

    def Equality.eval_string_vs_value(lvalue, rvalue, operator)
      throw(:done,
        ROXI::XPath::Function::String.eval(nil, lvalue).send(
          operator, ROXI::XPath::Function::String.eval(nil, rvalue)
        )
      )
    end

    def Equality.eval_nodes_vs_nodes(lvalue, rvalue, operator)
      if lvalue.instance_of? Array and rvalue.instance_of? Array
        throw(:done, 
          lvalue.any? do | left |
            rvalue.any? do | right |
              left.value.to_s.send(operator, right.value.to_s)
            end
          end
        )
      end
    end

    def Equality.eval_nodes_vs_value(lvalue, rvalue, operator)
      if lvalue.instance_of? Array or rvalue.instance_of? Array
        nodes, value = *Equality.nodes_as_lvalue(lvalue, rvalue)
        Equality.eval_nodes_vs_number(nodes, value, operator)
        Equality.eval_nodes_vs_string(nodes, value, operator)
        Equality.eval_nodes_vs_boolean(nodes, value, operator)
      end
    end

    def Equality.eval_value_vs_value(lvalue, rvalue, operator)
      Equality.eval_boolean_vs_value(lvalue, rvalue, operator)
      Equality.eval_numeric_vs_value(lvalue, rvalue, operator)
      Equality.eval_string_vs_value(lvalue, rvalue, operator)
    end

    def Equality.eval(lvalue, rvalue, operator)
      catch(:done) do
        Equality.eval_nodes_vs_nodes(lvalue, rvalue, operator)
        Equality.eval_nodes_vs_value(lvalue, rvalue, operator)
        Equality.eval_value_vs_value(lvalue, rvalue, operator)
      end
    end

  end


  class Relational < Equality

    def initialize(lexpression, rexpression, operator)
      @lexpression = lexpression
      @rexpression = rexpression
      @operator = operator
    end

    def eval(context)
      Relational.eval(
        @lexpression.eval(context),
        @rexpression.eval(context),
        @operator)
    end

    def Relational.eval(lvalue, rvalue, operator)
      catch(:done) do
        Equality.eval_nodes_vs_nodes(lvalue, rvalue, operator)
        Equality.eval_nodes_vs_value(lvalue, rvalue, operator)
        Equality.eval_numeric_vs_value(
          ROXI::XPath::Function::Number.eval(nil, lvalue),
          ROXI::XPath::Function::Number.eval(nil, rvalue),
          operator
        )
      end
    end

  end

  class Aritmetic

    def initialize(lexpression, rexpression, operator)
      @lexpression = lexpression
      @rexpression = rexpression
      @operator = operator
    end

    def eval(context)
      self.class.eval(
        @lexpression.eval(context),
        @rexpression.eval(context),
        @operator)
    end

    def Aritmetic.eval(lvalue, rvalue, operator)
      ROXI::XPath::Function::Number.eval(nil, lvalue).send(
        operator, ROXI::XPath::Function::Number.eval(nil, rvalue)
      )
    end

  end

end
