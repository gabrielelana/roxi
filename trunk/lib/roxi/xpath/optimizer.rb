module ROXI::XPath

  module Optimizer

    def self.optimize(expression)
      expression = expression.clone
      expression.gsub!(/\/\/([_*A-Za-z\x7F-\xFF][-_.A-Za-z\x7F-\xFF]*)/, '/descendant-or-self::\1')
      expression.gsub!(/\/\//, '/descendant-or-self::node()')
      expression
    end

  end

end
