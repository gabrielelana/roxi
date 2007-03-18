module ROXI::XPath::Operator

  include ROXI::XPath

  class And < Expression::Expression

    def And.eval(context, lvalue, rvalue)
      ROXI::XPath::Function::Boolean.eval(context, lvalue) and ROXI::XPath::Function::Boolean.eval(context, rvalue)
    end

  end

  class Or < Expression::Expression

    def Or.eval(context, lvalue, rvalue)
      ROXI::XPath::Function::Boolean.eval(context, lvalue) or ROXI::XPath::Function::Boolean.eval(context, rvalue)
    end

  end

  class Union < Expression::Expression

    def Union.eval(context, lvalue, rvalue)
      lvalue = ROXI::XPath::Function::NodeSet.eval(context, lvalue)
      rvalue = ROXI::XPath::Function::NodeSet.eval(context, rvalue)
      lvalue.concat(rvalue).uniq
    end

  end

  class Eq < Expression::Equality

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :==)
    end

    def Eq.eval(lvalue, rvalue)
      super(lvalue, rvalue, :==)
    end

  end

  class Neq < Expression::Equality

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :==)
    end

    def eval(context)
      !super
    end

    def Neq.eval(lvalue, rvalue)
      !super(lvalue, rvalue, :==)
    end

  end

  class Lt < Expression::Relational

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :<)
    end

    def Lt.eval(lvalue, rvalue)
      super(lvalue, rvalue, :<)
    end

  end

  class Let < Expression::Relational

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :<=)
    end

    def Let.eval(lvalue, rvalue)
      super(lvalue, rvalue, :<=)
    end

  end

  class Gt < Expression::Relational

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :>)
    end

    def Gt.eval(lvalue, rvalue)
      super(lvalue, rvalue, :>)
    end

  end

  class Get < Expression::Relational

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :>=)
    end

    def Get.eval(lvalue, rvalue)
      super(lvalue, rvalue, :>=)
    end

  end

  class Mul < Expression::Aritmetic

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :*)
    end

  end

  class Add < Expression::Aritmetic

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :+)
    end

  end

  class Sub < Expression::Aritmetic

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :-)
    end

  end

  class Div < Expression::Aritmetic

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :/)
    end

    def Div.eval(lvalue, rvalue, operator)
      lvalue = ROXI::XPath::Function::Number.eval(nil, lvalue).to_f
      rvalue = ROXI::XPath::Function::Number.eval(nil, rvalue).to_f
      lvalue.send(operator, rvalue)
    end

  end

  class Mod < Expression::Aritmetic

    def initialize(lexpression, rexpression)
      super(lexpression, rexpression, :%)
    end

    def Mod.eval(lvalue, rvalue, operator)
      lvalue = ROXI::XPath::Function::Number.eval(nil, lvalue).to_f
      rvalue = ROXI::XPath::Function::Number.eval(nil, rvalue).to_f
      lvalue - ((lvalue / rvalue).to_i * rvalue)
    end

  end

  class Neg < Expression::Expression

    def Neg.eval(context, value)
      -ROXI::XPath::Function::Number.eval(context, value)
    end

  end

end
