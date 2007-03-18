require 'roxi/xquery'
require 'test/unit'

include ROXI

class UseAsXQuery < Test::Unit::TestCase

  def setup
    @books = File.dirname(__FILE__) + '/../../res/books.xml'
  end

  def test_simple_query
    # =begin xquery
    # doc("books.xml")/bookstore/book[price<30]
    # =end
    
    books = XDocument.open(@books).xpath('/bookstore/book[price<30]')

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
    
    titles = XDocument.open(@books).xpath('/bookstore/book').from do | book |
      if book.child('price').value.to_f > 30
        book.child('title')
      end
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

    titles = XDocument.open(@books).xpath('/bookstore/book').from do | book |
      if book.child('price').value.to_f > 30
        book.child('title')
      end
    end.
      sort_by { | title | title.value }

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
      XDocument.open(@books).xpath('/bookstore/book/title').
        sort_by { | title | title.value }.from do | title |
          XElement.new('li', title)
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
      XDocument.open(@books).xpath('/bookstore/book').from do | book |
        if book.attribute('category').value == 'CHILDREN'
          XElement.new('child', book.child('title').value)
        else
          XElement.new('adult', book.child('title').value)
        end
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
          XDocument.open(@books).xpath('/bookstore/book').
            sort_by { | book | book.child('title').value }.from do | book |
              XElement.new('li',
                XAttribute.new('class', book.attribute('category').value),
                XText.new(book.child('title').value)
              )
            end
        )
      )
    )

    assert_equal 4, element.xpath('count(//li)')
  end

end
