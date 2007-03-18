require 'roxi/xpath'
require 'benchmark'

include ROXI
include ROXI::XPath

def assert_equal(expected, given)
  if expected != given
    raise "expected '#{expected}', but was '#{given}'"
  end
end

def check_result(result, expected_value, expected_type)
    begin
      case(expected_type)
      when 'count'
        assert_equal expected_value, result.size.to_s
      when 'string'
        assert_equal expected_value, result
      when 'double'
        assert_equal expected_value.to_f.to_s, result.to_f.to_s
      when 'boolean'
        expected_value = expected_value == 'true' ? true : false
        assert_equal expected_value, result
      end
    rescue
      return "raised exception: #{$!.message}"
    end
    return 'ok'
end
 

report = nil

XDocument.open('bench.xml') do | test |
  doc = nil
  total_compile_context_time = Benchmark::Tms.new
  total_compile_selection_time = Benchmark::Tms.new
  total_select_context_time = Benchmark::Tms.new
  total_select_selection_time = Benchmark::Tms.new

  load_time = Benchmark.measure {
    doc = XDocument.open('../res/' + test.xpath('//document/@url').only.value)
  }

  report = XDocument.new(
    XElement.new('report',

      test.xpath('//path').collect do | selection |

        context_query = if selection.attributes('context').empty?
          then '/'
          else selection.attribute('context').value
        end
        selection_query = selection.attribute('select').value
        expected_type = selection.attribute('type').value
        expected_value = selection.value

        context = nil
        selection = nil
        context_expression = nil
        selection_expression = nil

        compile_context_time = Benchmark.measure {
          context_expression = XPath::Builder.new(
            XPath::Optimizer.optimize(context_query)).build
        }

        select_context_time = Benchmark.measure {
          xpath_context = Context.new
          xpath_context.document = doc
          xpath_context.node = doc
          context = context_expression.eval(xpath_context)
        }

        compile_selection_time = Benchmark.measure {
          selection_expression = XPath::Builder.new(
            XPath::Optimizer.optimize(selection_query)).build
        }

        select_selection_time = Benchmark.measure {
          xpath_context = Context.new
          xpath_context.document = doc
          xpath_context.node = context
          selection = selection_expression.eval(xpath_context)
        }

        message = check_result(selection, expected_value, expected_type)

        total_compile_context_time += compile_context_time
        total_compile_selection_time += compile_selection_time
        total_select_context_time += select_context_time
        total_select_selection_time += select_selection_time

        XElement.new('selection',
          XAttribute.new('select', selection_query),
          XAttribute.new('context', context_query),
          XAttribute.new('check', message),
          XElement.new('compile_context', XAttribute.new('take', compile_context_time.real)),
          XElement.new('compile_selection', XAttribute.new('take', compile_selection_time.real)),
          XElement.new('select_context', XAttribute.new('take', select_context_time.real)),
          XElement.new('select_selection', XAttribute.new('take', select_selection_time.real))
        )
      end

    )
  )

  report.child('report').add(
    XElement.new('total',
      XElement.new('compile_all_contexts', XAttribute.new('take', total_compile_context_time.real)),
      XElement.new('compile_all_selections', XAttribute.new('take', total_compile_selection_time.real)),
      XElement.new('select_all_contexts', XAttribute.new('take', total_select_context_time.real)),
      XElement.new('select_all_selections', XAttribute.new('take', total_select_selection_time.real))
    )
  )
end

puts report.child('report').child('total')
puts report.xpath('//selection[@check != "ok"]')

require 'roxi/xquery'

def select_slowest(nodeset, header)
  puts "\n" + header
  XQuery.from(nodeset) do
    order_by(:descending) { | selection |
      selection.attribute('take').value.to_f
    }
    filter { | selections |
      selections[0..14]
    }
    select { | selection |
      query = selection.parent.attribute('select').value
      type = selection.name
      time = selection.attribute('take').value
      puts "#{type.gsub(/.*_/, '')} '#{query}' take #{time} seconds"
    }
  end
end


select_slowest(report.xpath('//select_selection | //select_context'), 'slowest selection:')
select_slowest(report.xpath('//compile_selection | //compile_context'), 'slowest compilation:')
