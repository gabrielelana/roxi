require 'roxi/xpath'
require 'test/unit'

module ROXI::XPath

  class TestParser < Test::Unit::TestCase
    include ROXI
    include ROXI::XPath

    def setup
      Builder.class_eval {
        def initialize(tokens)
          @tokens = Marshal::load(Marshal::dump(tokens))
        end
      }
    end

    def teardown
      Builder.class_eval {
        def initialize(string)
          @tokens = ROXI::XPath::Parser.new(string).parse
        end
      }
    end

    def assert_chain(chain)
      require 'pp'
      parsed_tokens = ROXI::XPath::Parser.new(chain[:query]).parse
      # pp parsed_tokens
      builded_expression = ROXI::XPath::Builder.new(chain[:tokens]).build
      # pp builded_expression
      assert_equal chain[:tokens], parsed_tokens
      assert_equal Marshal.dump(chain[:expression]), Marshal.dump(builded_expression)
    end

    def test_basic
      assert_chain(
        :query => '/',
        :tokens => [:absolute, []],
        :expression => Expression::AbsoluteLocationPath.new([])
      )

      assert_chain(
        :query => '//',
        :tokens => [:absolute, [[[:descendant_or_self], [:node], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          )
        ])
      )

      assert_chain(
        :query => 'child',
        :tokens => [:relative, [[[:child], [:qname, 'child'], []]]],
        :expression => Expression::RelativeLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child')
          )
        ])
      )

      assert_chain(
        :query => '/child',
        :tokens => [:absolute, [[[:child], [:qname, 'child'], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child')
          )
        ])
      )

      assert_chain(
        :query => '//child',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'child'], []]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child')
          )
        ])
      )

      assert_chain(
        :query => '/child/child',
        :tokens => [:absolute, [
          [[:child], [:qname, 'child'], []],
          [[:child], [:qname, 'child'], []]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child')
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child')
          )
        ])
      )
    end

    def test_literal
      assert_chain(
        :query => "'label'",
        :tokens => [:filter, [:literal, 'label'], []],
        :expression => Expression::Filter.new(
          Expression::Literal.new('label')
        )
      )

      assert_chain(
        :query => '"label"',
        :tokens => [:filter, [:literal, 'label'], []],
        :expression => Expression::Filter.new(
          Expression::Literal.new('label')
        )
      )

      assert_chain(
        :query => '1',
        :tokens => [:filter, [:number, 1.0], []],
        :expression => Expression::Filter.new(
          Expression::Literal.new(1.0)
        )
      )

      assert_chain(
        :query => '"1"',
        :tokens => [:filter, [:literal, '1'], []],
        :expression => Expression::Filter.new(
          Expression::Literal.new('1')
        )
      )

      assert_chain(
        :query => "'1'",
        :tokens => [:filter, [:literal, '1'], []],
        :expression => Expression::Filter.new(
          Expression::Literal.new('1')
        )
      )

    end

    def test_predicate
      assert_chain(
        :query => '/child[1]',
        :tokens => [:absolute, [
          [[:child], [:qname, 'child'], [[:filter, [:number, 1.0], []]]]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child'), [
              Expression::Predicate.new(
                Expression::Filter.new(
                  Expression::Literal.new(1.0)
                )
              )
            ]
          )
        ])
      )

      assert_chain(
        :query => '/child[1][1]',
        :tokens => [:absolute, [
          [[:child], [:qname, 'child'], [
            [:filter, [:number, 1.0], []],
            [:filter, [:number, 1.0], []],
          ]]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child'), [
              Expression::Predicate.new(
                Expression::Filter.new(
                  Expression::Literal.new(1.0)
                )
              ),
              Expression::Predicate.new(
                Expression::Filter.new(
                  Expression::Literal.new(1.0)
                )
              )
            ]
          )
        ])
      )

      assert_chain(
        :query => '/child[last() = 7]',
        :tokens => [:absolute, [
          [[:child], [:qname, 'child'], [
            [:eq, 
              [:filter, [:function, 'last', []], []],
              [:filter, [:number, 7.0], []]
            ]
          ]]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child'), [
              Expression::Predicate.new(
                Operator::Eq.new(
                  Expression::Filter.new(
                    Expression::Function.new('last', [])
                  ),
                  Expression::Filter.new(
                    Expression::Literal.new(7.0)
                  )
                )
              )
            ]
          )
        ])
      )

      assert_chain(
        :query => '//*[name() = /child]',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:all], [
            [:eq,
              [:filter, [:function, 'name', []], []],
              [:absolute, [
                [[:child], [:qname, 'child'], []]
              ]]
            ]
          ]]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new, []
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::All.new, [
              Expression::Predicate.new(
                Operator::Eq.new(
                  Expression::Filter.new(
                    Expression::Function.new('name', [])
                  ),
                  Expression::AbsoluteLocationPath.new([
                    Expression::LocationStep.new(
                      Axis::Child,
                      NodePattern::Name.new('child')
                    )
                  ])
                )
              )
            ]
          )
        ])
      )

      assert_chain(
        :query => '/child[/child/@id=1]',
        :tokens => [:absolute, [
          [[:child], [:qname, 'child'], [
            [:eq,
              [:absolute, [
                [[:child], [:qname, 'child'], []],
                [[:attribute], [:qname, 'id'], []]
              ]],
              [:filter, [:number, 1.0], []]
            ]
          ]]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child'), [
              Expression::Predicate.new(
                Operator::Eq.new(
                  Expression::AbsoluteLocationPath.new([
                    Expression::LocationStep.new(
                      Axis::Child,
                      NodePattern::Name.new('child')
                    ),
                    Expression::LocationStep.new(
                      Axis::Attribute,
                      NodePattern::Name.new('id')
                    )
                  ]),
                  Expression::Filter.new(
                    Expression::Literal.new(1.0)
                  )
                )
              )
            ]
          )
        ])
      )
    end

    def test_functions
      assert_chain(
        :query => 'count(*)',
        :tokens => [:filter, [:function, 'count', [
          [:relative, [[[:child], [:all], []]]]
        ]], []],
        :expression => Expression::Filter.new(
          Expression::Function.new('count', [
            Expression::RelativeLocationPath.new([
              Expression::LocationStep.new(
                Axis::Child,
                NodePattern::All.new
              )
            ])
          ])
        )
      )

      assert_chain(
        :query => 'count(/child)',
        :tokens => [:filter, [:function, 'count', [
          [:absolute, [[[:child], [:qname, 'child'], []]]]
        ]], []],
        :expression => Expression::Filter.new(
          Expression::Function.new('count', [
            Expression::AbsoluteLocationPath.new([
              Expression::LocationStep.new(
                Axis::Child,
                NodePattern::Name.new('child')
              )
            ])
          ])
        )
      )

      assert_chain(
        :query => 'numbers(1*1)',
        :tokens => [:filter, [:function, 'numbers', [
          [:mul,
            [:filter, [:number, 1.0], []],
            [:filter, [:number, 1.0], []]
          ]
        ]], []],
        :expression => Expression::Filter.new(
          Expression::Function.new('numbers', [
            Operator::Mul.new(
              Expression::Filter.new(Expression::Literal.new(1.0)),
              Expression::Filter.new(Expression::Literal.new(1.0))
            )
          ])
        )
      )

      assert_chain(
        :query => 'starts-with(name(), "label")',
        :tokens => [:filter, [:function, 'starts-with', [
          [:filter, [:function, 'name', []], []],
          [:filter, [:literal, 'label'], []]
        ]], []],
        :expression => Expression::Filter.new(
          Expression::Function.new('starts-with', [
            Expression::Filter.new(
              Expression::Function.new('name')),
            Expression::Filter.new(Expression::Literal.new('label'))
          ])
        )
      )
      
      assert_chain(
        :query => 'concat(1, 2, 3, (4 * 1))',
        :tokens => [:filter, [:function, 'concat', [
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 2.0], []],
          [:filter, [:number, 3.0], []],
          [:filter,
            [:expression,
              [:mul,
                [:filter, [:number, 4.0], []],
                [:filter, [:number, 1.0], []]
              ]
            ], []
          ]
        ]], []],
        :expression => Expression::Filter.new(
          Expression::Function.new('concat', [
            Expression::Filter.new(Expression::Literal.new(1.0)),
            Expression::Filter.new(Expression::Literal.new(2.0)),
            Expression::Filter.new(Expression::Literal.new(3.0)),
            Expression::Filter.new(
              Expression::Expression.new(
                Operator::Mul.new(
                  Expression::Filter.new(Expression::Literal.new(4.0)),
                  Expression::Filter.new(Expression::Literal.new(1.0))
                )
              )
            )
          ])
        )
      )
      
      assert_chain(
        :query => 'external-function(1, 2, 3, 4)',
        :tokens => [:filter, [:function, 'external-function', [
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 2.0], []],
          [:filter, [:number, 3.0], []],
          [:filter, [:number, 4.0], []]
        ]], []],
        :expression => Expression::Filter.new(
          Expression::Function.new('external-function', [
            Expression::Filter.new(Expression::Literal.new(1.0)),
            Expression::Filter.new(Expression::Literal.new(2.0)),
            Expression::Filter.new(Expression::Literal.new(3.0)),
            Expression::Filter.new(Expression::Literal.new(4.0))
          ])
        )
      )
      
      assert_chain(
        :query => '//child[position() = floor(last() div 2 + 0.5) or position() = ceiling(last() div 2 + 0.5)]',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'child'], [
            [:or,
              [:eq,
                [:filter, [:function, 'position', []], []],
                [:filter, [:function, 'floor', [
                  [:add,
                    [:div,
                      [:filter, [:function, 'last', []], []],
                      [:filter, [:number, 2.0], []]
                    ],
                    [:filter, [:number, 0.5], []]
                  ]
                ]], []]
              ],
              [:eq,
                [:filter, [:function, 'position', []], []],
                [:filter, [:function, 'ceiling', [
                  [:add,
                    [:div,
                      [:filter, [:function, 'last', []], []],
                      [:filter, [:number, 2.0], []]
                    ],
                    [:filter, [:number, 0.5], []]
                  ]
                ]], []]
              ]
            ]
          ]]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child'), [
              Expression::Predicate.new(
                Operator::Or.new(
                  Operator::Eq.new(
                    Expression::Filter.new(
                      Expression::Function.new('position')
                    ),
                    Expression::Filter.new(
                      Expression::Function.new('floor', [
                        Operator::Add.new(
                          Operator::Div.new(
                            Expression::Filter.new(
                              Expression::Function.new('last')
                            ),
                            Expression::Filter.new(
                              Expression::Literal.new(2.0)
                            )
                          ),
                          Expression::Filter.new(
                            Expression::Literal.new(0.5)
                          )
                        )
                      ])
                    )
                  ),
                  Operator::Eq.new(
                    Expression::Filter.new(
                      Expression::Function.new('position')
                    ),
                    Expression::Filter.new(
                      Expression::Function.new('ceiling', [
                        Operator::Add.new(
                          Operator::Div.new(
                            Expression::Filter.new(
                              Expression::Function.new('last')
                            ),
                            Expression::Filter.new(
                              Expression::Literal.new(2.0)
                            )
                          ),
                          Expression::Filter.new(
                            Expression::Literal.new(0.5)
                          )
                        )
                      ])
                    )
                  )
                )
              )
            ]
          )
        ])
      )
    end

    def test_abbreviate
      # .
      # ..
      # /.
      # /..
      # /*
      # /@id
      # /@*
      # /child[not(@*)]
      # //*
      # //child//*
      # /*/*/child
      # .//.
      # .//..
      # ./.[.='label']/@id
    end

    def test_pattern
      assert_chain(
        :query => '/text()',
        :tokens => [:absolute, [[[:child], [:text], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Text.new
          )
        ])
      )

      assert_chain(
        :query => '/text("regexp")',
        :tokens => [:absolute, [[[:child], [:text, 'regexp'], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Text.new('regexp')
          )
        ])
      )

      assert_chain(
        :query => '/comment()',
        :tokens => [:absolute, [[[:child], [:comment], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Comment.new
          )
        ])
      )

      assert_chain(
        :query => '/comment("regexp")',
        :tokens => [:absolute, [[[:child], [:comment, 'regexp'], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Comment.new('regexp')
          )
        ])
      )

      assert_chain(
        :query => '/child::node()',
        :tokens => [:absolute, [[[:child], [:node], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Node.new
          )
        ])
      )

      assert_chain(
        :query => '/child::*',
        :tokens => [:absolute, [[[:child], [:all], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::All.new
          )
        ])
      )

      assert_chain(
        :query => '/child::child',
        :tokens => [:absolute, [[[:child], [:qname, 'child'], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child')
          )
        ])
      )

      assert_chain(
        :query => '/child::prefix:child',
        :tokens => [:absolute, [[[:child], [:qname, 'child', 'prefix'], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child', 'prefix')
          )
        ])
      )

      assert_chain(
        :query => '/processing-instruction()',
        :tokens => [:absolute, [[[:child], [:processing_instruction], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::ProcessingInstruction.new
          )
        ])
      )

      assert_chain(
        :query => '/processing-instruction("php")',
        :tokens => [:absolute, [[[:child], [:processing_instruction, 'php'], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::ProcessingInstruction.new('php')
          )
        ])
      )

      assert_chain(
        :query => "/processing-instruction('php')",
        :tokens => [:absolute, [[[:child], [:processing_instruction, 'php'], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::ProcessingInstruction.new('php')
          )
        ])
      )

      assert_raise(SyntaxError) {
        assert_chain(
          :query => '/node("fake")',
          :tokens => nil,
          :expression => nil
        )
      }
    end

    def test_axis
      assert_chain(
        :query => '/child::a',
        :tokens => [:absolute, [[[:child], [:qname, 'a'], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          )
        ])
      )

      assert_chain(
        :query => '/descendant::*',
        :tokens => [:absolute, [[[:descendant], [:all], []]]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Descendant,
            NodePattern::All.new
          )
        ])
      )

      assert_chain(
        :query => '/descendant::node()/descendant::a',
        :tokens => [:absolute, [
          [[:descendant], [:node], []],
          [[:descendant], [:qname, 'a'], []]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Descendant,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Descendant,
            NodePattern::Name.new('a')
          )
        ])
      )

      assert_chain(
        :query => '//a/descendant::b',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'a'], []],
          [[:descendant], [:qname, 'b'], []]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Descendant,
            NodePattern::Name.new('b')
          )
        ])
      )

      assert_chain(
        :query => '/descendant-or-self::*',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:all], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::All.new
          )
        ])
      )

      assert_chain(
        :query => '/descendant-or-self::node()/descendant::a',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:descendant], [:qname, 'a'], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Descendant,
            NodePattern::Name.new('a')
          )
        ])
      )

      assert_chain(
        :query => '//a/parent::*',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'a'], []],
          [[:parent], [:all], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Parent,
            NodePattern::All.new
          )
        ])
      )

      assert_chain(
        :query => '//a/ancestor::b',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'a'], []],
          [[:ancestor], [:qname, 'b'], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Ancestor,
            NodePattern::Name.new('b')
          )
        ])
      )

      assert_chain(
        :query => '//a/ancestor-or-self::b',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'a'], []],
          [[:ancestor_or_self], [:qname, 'b'], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::AncestorOrSelf,
            NodePattern::Name.new('b')
          )
        ])
      )

      assert_chain(
        :query => '/a/b/following-sibling::c',
        :tokens => [:absolute, [
          [[:child], [:qname, 'a'], []],
          [[:child], [:qname, 'b'], []],
          [[:following_sibling], [:qname, 'c'], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('b')
          ),
          Expression::LocationStep.new(
            Axis::FollowingSibling,
            NodePattern::Name.new('c')
          )
        ])
      )

      assert_chain(
        :query => '/a/b/preceding-sibling::c',
        :tokens => [:absolute, [
          [[:child], [:qname, 'a'], []],
          [[:child], [:qname, 'b'], []],
          [[:preceding_sibling], [:qname, 'c'], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('b')
          ),
          Expression::LocationStep.new(
            Axis::PrecedingSibling,
            NodePattern::Name.new('c')
          )
        ])
      )

      assert_chain(
        :query => '//a/following::*',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'a'], []],
          [[:following], [:all], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Following,
            NodePattern::All.new
          )
        ])
      )

      assert_chain(
        :query => '//a/preceding::*',
        :tokens => [:absolute, [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'a'], []],
          [[:preceding], [:all], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::DescendantOrSelf,
            NodePattern::Node.new
          ),
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Preceding,
            NodePattern::All.new
          )
        ])
      )

      assert_chain(
        :query => '/a/self::node()',
        :tokens => [:absolute, [
          [[:child], [:qname, 'a'], []],
          [[:self], [:node], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Self,
            NodePattern::Node.new
          )
        ])
      )

      assert_chain(
        :query => '/a/attribute::*',
        :tokens => [:absolute, [
          [[:child], [:qname, 'a'], []],
          [[:attribute], [:all], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Attribute,
            NodePattern::All.new
          )
        ])
      )

      assert_chain(
        :query => '/a/attribute::prefix:b',
        :tokens => [:absolute, [
          [[:child], [:qname, 'a'], []],
          [[:attribute], [:qname, 'b', 'prefix'], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Attribute,
            NodePattern::Name.new('b', 'prefix')
          )
        ])
      )

      assert_chain(
        :query => '/a/namespace::node()',
        :tokens => [:absolute, [
          [[:child], [:qname, 'a'], []],
          [[:namespace], [:node], []],
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('a')
          ),
          Expression::LocationStep.new(
            Axis::Namespace,
            NodePattern::Node.new
          )
        ])
      )
    end

    def test_aritmetic_expression
      assert_chain(
        :query => '1 + 1',
        :tokens => [:add,
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 1.0], []]
        ],
        :expression => Operator::Add.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => '1 * 1',
        :tokens => [:mul,
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 1.0], []]
        ],
        :expression => Operator::Mul.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => '-1',
        :tokens => [:neg, [:filter, [:number, 1.0], []]],
        :expression => Operator::Neg.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => '1 mod 1',
        :tokens => [:mod,
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 1.0], []]
        ],
        :expression => Operator::Mod.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => '1 div 1',
        :tokens => [:div,
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 1.0], []]
        ],
        :expression => Operator::Div.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => 'string(1 + 1)',
        :tokens => [:filter,
          [:function, 'string', [
            [:add,
              [:filter, [:number, 1.0], []],
              [:filter, [:number, 1.0], []]
            ]
          ]], []
        ],
        :expression => Expression::Filter.new(
          Expression::Function.new('string', [
            Operator::Add.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              ),
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            )
          ])
        )
      )

      assert_chain(
        :query => '/child[1 + 1]',
        :tokens => [:absolute, [
          [[:child], [:qname, 'child'], [
            [:add,
              [:filter, [:number, 1.0], []],
              [:filter, [:number, 1.0], []]
            ]
          ]]
        ]],
        :expression => Expression::AbsoluteLocationPath.new([
          Expression::LocationStep.new(
            Axis::Child,
            NodePattern::Name.new('child'), [
              Expression::Predicate.new(
                Operator::Add.new(
                  Expression::Filter.new(
                    Expression::Literal.new(1.0)
                  ),
                  Expression::Filter.new(
                    Expression::Literal.new(1.0)
                  )
                )
              )
            ]
          )
        ])
      )
    end

    def test_relational_expression
      assert_chain(
        :query => '1 = 1',
        :tokens => [:eq,
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 1.0], []]
        ],
        :expression => Operator::Eq.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => '1 != 2',
        :tokens => [:neq,
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 2.0], []]
        ],
        :expression => Operator::Neq.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(2.0)
          )
        )
      )

      assert_chain(
        :query => '@id = 1',
        :tokens => [:eq,
          [:relative, [
            [[:attribute], [:qname, 'id'], []]
          ]],
          [:filter, [:number, 1.0], []]
        ],
        :expression => Operator::Eq.new(
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Attribute,
              NodePattern::Name.new('id')
            )
          ]),
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => '1 < 2',
        :tokens => [:lt,
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 2.0], []]
        ],
        :expression => Operator::Lt.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(2.0)
          )
        )
      )

      assert_chain(
        :query => '1 <= 2',
        :tokens => [:let,
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 2.0], []]
        ],
        :expression => Operator::Let.new(
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(2.0)
          )
        )
      )

      assert_chain(
        :query => '2 > 1',
        :tokens => [:gt,
          [:filter, [:number, 2.0], []],
          [:filter, [:number, 1.0], []]
        ],
        :expression => Operator::Gt.new(
          Expression::Filter.new(
            Expression::Literal.new(2.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => '2 >= 1',
        :tokens => [:get,
          [:filter, [:number, 2.0], []],
          [:filter, [:number, 1.0], []]
        ],
        :expression => Operator::Get.new(
          Expression::Filter.new(
            Expression::Literal.new(2.0)
          ),
          Expression::Filter.new(
            Expression::Literal.new(1.0)
          )
        )
      )

      assert_chain(
        :query => '/child and @id',
        :tokens => [:and,
          [:absolute, [[[:child], [:qname, 'child'], []]]],
          [:relative, [[[:attribute], [:qname, 'id'], []]]]
        ],
        :expression => Operator::And.new(
          Expression::AbsoluteLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ]),
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Attribute,
              NodePattern::Name.new('id')
            )
          ])
        )
      )

      assert_chain(
        :query => '/child or @id',
        :tokens => [:or,
          [:absolute, [[[:child], [:qname, 'child'], []]]],
          [:relative, [[[:attribute], [:qname, 'id'], []]]]
        ],
        :expression => Operator::Or.new(
          Expression::AbsoluteLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ]),
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Attribute,
              NodePattern::Name.new('id')
            )
          ])
        )
      )

      assert_chain(
        :query => '/child and /child or /child',
        :tokens => [:or,
          [:and,
            [:absolute, [[[:child], [:qname, 'child'], []]]],
            [:absolute, [[[:child], [:qname, 'child'], []]]]
          ],
          [:absolute, [[[:child], [:qname, 'child'], []]]]
        ],
        :expression => Operator::Or.new(
          Operator::And.new(
            Expression::AbsoluteLocationPath.new([
              Expression::LocationStep.new(
                Axis::Child,
                NodePattern::Name.new('child')
              )
            ]),
            Expression::AbsoluteLocationPath.new([
              Expression::LocationStep.new(
                Axis::Child,
                NodePattern::Name.new('child')
              )
            ])
          ),
          Expression::AbsoluteLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ])
        )
      )

      assert_chain(
        :query => '/child or /child and /child',
        :tokens => [:or,
          [:absolute, [[[:child], [:qname, 'child'], []]]],
          [:and,
            [:absolute, [[[:child], [:qname, 'child'], []]]],
            [:absolute, [[[:child], [:qname, 'child'], []]]]
          ]
        ],
        :expression => Operator::Or.new(
          Expression::AbsoluteLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ]),
          Operator::And.new(
            Expression::AbsoluteLocationPath.new([
              Expression::LocationStep.new(
                Axis::Child,
                NodePattern::Name.new('child')
              )
            ]),
            Expression::AbsoluteLocationPath.new([
              Expression::LocationStep.new(
                Axis::Child,
                NodePattern::Name.new('child')
              )
            ])
          )
        )
      )
    end

    def test_union_expression
      # //child | //child
      # /child | /child/łid | /child[1]
      # /child[//ł* | /child]
      # count(/child | /child)
    end

    def test_filter_expression
      assert_chain(
        :query => '$var',
        :tokens => [:filter, [:variable, 'var'], []],
        :expression => Expression::Filter.new(
          Expression::Variable.new('var')
        )
      )

      assert_chain(
        :query => '$var/child',
        :tokens => [:filter, [:variable, 'var'], [], [
          [[:child], [:qname, 'child'], []]
        ]],
        :expression => Expression::Filter.new(
          Expression::Variable.new('var'), [],
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ])
        )
      )

      assert_chain(
        :query => '$var//child',
        :tokens => [:filter, [:variable, 'var'], [], [
          [[:descendant_or_self], [:node], []],
          [[:child], [:qname, 'child'], []]
        ]],
        :expression => Expression::Filter.new(
          Expression::Variable.new('var'), [],
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::DescendantOrSelf,
              NodePattern::Node.new
            ),
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ])
        )
      )

      assert_chain(
        :query => '$var[1]/child',
        :tokens => [:filter, [:variable, 'var'], [
          [:filter, [:number, 1.0], []]], [
          [[:child], [:qname, 'child'], []]
        ]],
        :expression => Expression::Filter.new(
          Expression::Variable.new('var'), [
            Expression::Predicate.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            )
          ],
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ])
        )
      )

      assert_chain(
        :query => '$var[1][1]/child',
        :tokens => [:filter, [:variable, 'var'], [
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 1.0], []]
        ], [
          [[:child], [:qname, 'child'], []]
        ]],
        :expression => Expression::Filter.new(
          Expression::Variable.new('var'), [
            Expression::Predicate.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            ),
            Expression::Predicate.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            )
          ],
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ])
        )
      )

      assert_chain(
        :query => '$var[1][1]/.',
        :tokens => [:filter, [:variable, 'var'], [
          [:filter, [:number, 1.0], []],
          [:filter, [:number, 1.0], []]
        ], [
          [[:self], [:node], []]
        ]],
        :expression => Expression::Filter.new(
          Expression::Variable.new('var'), [
            Expression::Predicate.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            ),
            Expression::Predicate.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            )
          ],
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Self,
              NodePattern::Node.new
            )
          ])
        )
      )

      assert_chain(
        :query => '(/child|$var)[1]',
        :tokens => [:filter,
          [:expression,
            [:union,
              [:absolute, [[[:child], [:qname, 'child'], []]]],
              [:filter, [:variable, 'var'], []]
            ]
          ],
          [[:filter, [:number, 1.0], []]]
        ],
        :expression => Expression::Filter.new(
          Expression::Expression.new(
            Operator::Union.new(
              Expression::AbsoluteLocationPath.new([
                Expression::LocationStep.new(
                  Axis::Child,
                  NodePattern::Name.new('child')
                )
              ]),
              Expression::Filter.new(
                Expression::Variable.new('var')
              )
            )
          ), [
            Expression::Predicate.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            )
          ]
        )
      )

      assert_chain(
        :query => '(/child|$var)/child',
        :tokens => [:filter,
          [:expression,
            [:union,
              [:absolute, [[[:child], [:qname, 'child'], []]]],
              [:filter, [:variable, 'var'], []]
            ]
          ], [],
          [[[:child], [:qname, 'child'], []]]
        ],
        :expression => Expression::Filter.new(
          Expression::Expression.new(
            Operator::Union.new(
              Expression::AbsoluteLocationPath.new([
                Expression::LocationStep.new(
                  Axis::Child,
                  NodePattern::Name.new('child')
                )
              ]),
              Expression::Filter.new(
                Expression::Variable.new('var')
              )
            )
          ), [],
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ])
        )
      )

      assert_chain(
        :query => '(/child|$var)[1]/child',
        :tokens => [:filter,
          [:expression,
            [:union,
              [:absolute, [[[:child], [:qname, 'child'], []]]],
              [:filter, [:variable, 'var'], []]
            ]
          ], [
            [:filter, [:number, 1.0], []]
          ],
          [[[:child], [:qname, 'child'], []]]
        ],
        :expression => Expression::Filter.new(
          Expression::Expression.new(
            Operator::Union.new(
              Expression::AbsoluteLocationPath.new([
                Expression::LocationStep.new(
                  Axis::Child,
                  NodePattern::Name.new('child')
                )
              ]),
              Expression::Filter.new(
                Expression::Variable.new('var')
              )
            )
          ), [
            Expression::Predicate.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            )
          ],
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ])
        )
      )

      assert_chain(
        :query => '(/child|$var)[1]//child',
        :tokens => [:filter,
          [:expression,
            [:union,
              [:absolute, [[[:child], [:qname, 'child'], []]]],
              [:filter, [:variable, 'var'], []]
            ]
          ], [
            [:filter, [:number, 1.0], []]
          ],
          [
            [[:descendant_or_self], [:node], []],
            [[:child], [:qname, 'child'], []]
          ]
        ],
        :expression => Expression::Filter.new(
          Expression::Expression.new(
            Operator::Union.new(
              Expression::AbsoluteLocationPath.new([
                Expression::LocationStep.new(
                  Axis::Child,
                  NodePattern::Name.new('child')
                )
              ]),
              Expression::Filter.new(
                Expression::Variable.new('var')
              )
            )
          ), [
            Expression::Predicate.new(
              Expression::Filter.new(
                Expression::Literal.new(1.0)
              )
            )
          ],
          Expression::RelativeLocationPath.new([
            Expression::LocationStep.new(
              Axis::DescendantOrSelf,
              NodePattern::Node.new
            ),
            Expression::LocationStep.new(
              Axis::Child,
              NodePattern::Name.new('child')
            )
          ])
        )
      )
    end

    def test_parenthesize
      # (1 * 1) = 1
      # 1 * (1 = 1)
      # //a/b[2]
      # (//a/b)[2]
      # - (5 * 5)
      # - 5 * 5
      # (- 5) * 5
    end

  end

end
