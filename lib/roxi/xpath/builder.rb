module ROXI::XPath

  class Builder

    def initialize(string)
      begin
        @tokens = Parser.new(string).parse
      rescue
        raise SyntaxError, "xpath: #{string}"
      end
    end

    def build
      build_expression(@tokens)
    end

    def build_expression(tokens)
      return nil if tokens.nil? or tokens.empty?
      case token = tokens.shift
      when :absolute
        build_location_path(Expression::AbsoluteLocationPath, tokens.shift)
      when :relative
        build_location_path(Expression::RelativeLocationPath, tokens.shift)
      when :filter
        build_filter_expression(tokens)
      when :eq
        Operator::Eq.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :neq
        Operator::Neq.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :lt
        Operator::Lt.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :let
        Operator::Let.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :gt
        Operator::Gt.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :get
        Operator::Get.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :add
        Operator::Add.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :mul
        Operator::Mul.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :neg
        Operator::Neg.new(
          build_expression(tokens.shift)
        )
      when :mod
        Operator::Mod.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :div
        Operator::Div.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :and
        Operator::And.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :or
        Operator::Or.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      when :union
        Operator::Union.new(
          build_expression(tokens.shift),
          build_expression(tokens.shift)
        )
      end
    end

    def build_location_path(location_path, location_steps)
      location_path.new(build_location_steps(location_steps))
    end

    def build_predicates(tokens)
      tokens.inject([]) do | predicates, predicate |
        predicates << Expression::Predicate.new(build_expression(predicate))
      end
    end

    def build_location_steps(location_steps)
      return [] if location_steps.nil? or location_steps.empty?
      location_steps.inject([]) do | steps, tokens |
        steps << build_location_step(tokens)
      end
    end

    def build_location_step(tokens)
      Expression::LocationStep.new(
        build_axis(tokens.shift),
        build_pattern(tokens.shift),
        build_predicates(tokens.shift)
      )
    end

    def build_axis(tokens)
      case tokens.shift
      when :self
        Axis::Self
      when :parent
        Axis::Parent
      when :ancestor
        Axis::Ancestor
      when :ancestor_or_self
        Axis::AncestorOrSelf
      when :child
        Axis::Child
      when :descendant
        Axis::Descendant
      when :descendant_or_self
        Axis::DescendantOrSelf
      when :following
        Axis::Following
      when :following_sibling
        Axis::FollowingSibling
      when :preceding
        Axis::Preceding
      when :preceding_sibling
        Axis::PrecedingSibling
      when :attribute
        Axis::Attribute
      when :namespace
        Axis::Namespace
      end
    end

    def build_pattern(tokens)
      case tokens.shift
      when :all
        NodePattern::All.new
      when :node
        NodePattern::Node.new
      when :qname
        NodePattern::Name.new(tokens.shift, tokens.shift)
      when :text
        NodePattern::Text.new(tokens.shift)
      when :comment
        NodePattern::Comment.new(tokens.shift)
      when :processing_instruction
        NodePattern::ProcessingInstruction.new(tokens.shift)
      end
    end

    def build_function(tokens)
      Expression::Function.new(tokens.shift, build_function_args(tokens.shift))
    end

    def build_function_args(tokens)
      tokens.inject([]) do | args, arg |
        args << build_expression(arg)
      end
    end

    def build_primary_expression(tokens)
      case token = tokens.shift
      when :literal, :number
        Expression::Literal.new(tokens.shift) 
      when :variable
        Expression::Variable.new(tokens.shift)
      when :expression
        Expression::Expression.new(
          build_expression(tokens.shift)
        )
      when :function
        build_function(tokens)
      end
    end

    def build_filter_expression(tokens)
      Expression::Filter.new(
        build_primary_expression(tokens.shift),
        build_predicates(tokens.shift),
        if not tokens.empty?
          build_location_path(Expression::RelativeLocationPath, tokens.shift)
        end
      )
    end

  end

end
