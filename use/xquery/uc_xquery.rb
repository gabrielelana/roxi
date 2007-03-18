require 'roxi/xquery'
require 'test/unit'

include ROXI

class XQueryExamples < Test::Unit::TestCase

  def setup
    @books = File.dirname(__FILE__) + '/../../res/books.xml'
  end

  def test_simple_query
    # =begin xquery
    # doc("books.xml")/bookstore/book[price<30]
    # =end
    
    books = XQuery.from(XDocument.open(@books).xpath('/bookstore/book')) do
      where { | book | book.child('price').to_n < 30 }
    end

    assert_equal 1, books.size
    assert_equal 'Harry Potter', books.only.child('title').value
    assert_equal 29.99, books.only.child('price').value.to_f
  end

  def test_query_with_explicit_clause
    # =begin xquery
    # for $x in doc("books.xml")/bookstore/book
    # where $x/price>30
    # return $x/title
    # =end
   
    titles = XQuery.from(XDocument.open(@books).xpath('/bookstore/book')) do
      where { | book | book.child('price').to_n > 30 }
      select { | book | book.child('title') }
    end
    
    assert_equal 2, titles.size
    assert_equal 'XQuery Kick Start', titles[0].value
    assert_equal 'Learning XML', titles[1].value
  end

  def test_query_with_explicit_clause_with_order
    # =begin xquery
    # for $x in doc("books.xml")/bookstore/book
    # where $x/price>30
    # order by $x/title
    # return $x/title
    # =end
   
    titles = XQuery.from(XDocument.open(@books).xpath('/bookstore/book')) do
      where { | book | book.child('price').to_n > 30 }
      order_by { | book | book.child('title').value }
      select { | book | book.child('title') }
    end

    assert_equal 2, titles.size
    assert_equal 'Learning XML', titles[0].value
    assert_equal 'XQuery Kick Start', titles[1].value
  end

  def test_create_elements_with_query
    # =begin xquery
    # <ul> {
    #   for $x in doc("books.xml")/bookstore/book/title
    #   order by $x
    #   return <li>{$x}</li>
    # }
    # </ul>
    # =end
   
    element = XElement.new('ul',
      XQuery.from(XDocument.open(@books).xpath('/bookstore/book/title')) do
        order_by { | title | title.value }
        select { | title | XElement.new('li', title) }
      end
    )

    assert_equal 4, element.xpath('count(/li/title)')
  end

  def test_create_elements_with_conditions
    # =begin xquery
    # <books> {
    #   for $x in doc("books.xml")/bookstore/book
    #     return	if ($x/@category="CHILDREN")
    #     then <child>{data($x/title)}</child>
    #     else <adult>{data($x/title)}</adult>
    # }
    # </books>
    # =end

    element = XElement.new('books',
      XQuery.from(XDocument.open(@books).xpath('/bookstore/book')) do
        select { | book | 
          if book.attribute('category').value == 'CHILDREN'
            XElement.new('child', book.child('title').value)
          else
            XElement.new('adult', book.child('title').value)
          end
        }
      end
    )

    assert_equal 3, element.xpath('count(/adult)')
    assert_equal 1, element.xpath('count(/child)')
  end

  def test_adding_attributes
    # =begin xquery
    # <html>
    # <body>
    # <h1>Bookstore</h1>
    #
    # <ul>
    # {
    # for $x in doc("books.xml")/bookstore/book
    # order by $x/title
    # return <li class="{data($x/@category)}">{data($x/title)}</li>
    # }
    # </ul>
    #
    # </body>
    # </html>
    # =end

    element = XElement.new('html',
      XElement.new('body',
        XElement.new('h1', 'Bookstore'),
        XElement.new('ul',
          XQuery.from(XDocument.open(@books).xpath('/bookstore/book')) do
            order_by { | book | book.child('title').value }
            select { | book |
              XElement.new('li',
                XAttribute.new('class', book.attribute('category').value),
                XText.new(book.child('title').value)
              )
            }
          end
        )
      )
    )

    assert_equal 4, element.xpath('count(//li)')
  end

  def test_group_by
    # group_by is not supported by xquery

    element = XElement.new('years',
      XQuery.from(XDocument.open(@books).xpath('numbers(//year)')) do

        group_by do | years |
          result = years.inject(Hash.new(0)) do | result, year |
            result[year] += 1
            result
          end
          result.keys.zip(result.values)
        end
        
        select do | year, count |
          XElement.new('year',
            XAttribute.new('value', year),
            XAttribute.new('count', count)
          )
        end

      end
    )

    assert_equal 2, element.xpath('number(/year[@value=2003]/@count)')
    assert_equal 2, element.xpath('number(/year[@value=2005]/@count)')
  end

end
