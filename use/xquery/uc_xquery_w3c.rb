require 'roxi/xquery'
require 'test/unit'

include ROXI

# query from http://www.w3.org/TR/2005/WD-xquery-use-cases-20050915/
class XQueryW3CUseCases < Test::Unit::TestCase

  def initialize(name)
    super(name)
    @bib = File.dirname(__FILE__) + '/../../res/bib.xml'
    @book = File.dirname(__FILE__) + '/../../res/book.xml'
    @prices = File.dirname(__FILE__) + '/../../res/prices.xml'
    @reviews = File.dirname(__FILE__) + '/../../res/reviews.xml'
  end

  def test_1_1_9_5
    # =begin xquery
    # <books-with-prices>
    # {
    #   for $b in doc("http://bstore1.example.com/bib.xml")//book,
    #       $a in doc("http://bstore2.example.com/reviews.xml")//entry
    #     where $b/title = $a/title
    #     return
    #       <book-with-prices>
    #         { $b/title }
    #         <price-bstore2>{ $a/price/text() }</price-bstore2>
    #         <price-bstore1>{ $b/price/text() }</price-bstore1>
    #       </book-with-prices>
    # }
    # </books-with-prices> =begin xquery
    # =end

    element = XElement.new('books-with-prices',
      XQuery.from(
        XDocument.open(@bib).xpath('//book'),
        XDocument.open(@reviews).xpath('//entry')) do

        where { | book, entry |
          book.child('title').value == entry.child('title').value
        }

        select { | book, entry |
          XElement.new('book-with-prices',
            book.child('title'),
            XElement.new('price-bstore2', entry.child('price').value),
            XElement.new('price-bstore1', book.child('price').value)
          )
        }
      end
    )
    
    assert_equal true, element.xpath(
      '/book-with-prices[title = "TCP/IP Illustrated"]/price-bstore1' +
      ' = ' +
      '/book-with-prices[title = "TCP/IP Illustrated"]/price-bstore2'
    )
    assert_equal false, element.xpath(
      '/book-with-prices[title = "Data on the Web"]/price-bstore1' +
      ' = ' +
      '/book-with-prices[title = "Data on the Web"]/price-bstore2'
    )
  end

  def test_1_1_9_6
    # =begin xquery
    # <bib>
    # {
    #   for $b in doc("http://bstore1.example.com/bib.xml")//book
    #   where count($b/author) > 0
    #   return
    #     <book>
    #     { $b/title }
    #     {
    #       for $a in $b/author[position()<3]  
    #       return $a
    #     }
    #     {
    #       if (count($b/author) > 2)
    #         then <et-al/>
    #         else ()
    #     }
    #     </book>
    # }
    # </bib>
    # =end
    
    element = XElement.new('bib',
      XQuery.from(XDocument.open(@bib).xpath('//book')) do
        where { | book | book.children('author').size > 0 }
        select { | book |
          XElement.new('book',
            book.child('title'),
            book.xpath('author[position()<3]'),
            if (book.children('author').size > 2)
              XElement.new('et-al')
            end
          )
        }
      end
    )

    dataOnTheWeb = element.xpath('/book[title = "Data on the Web"]').only
    assert_equal 2, dataOnTheWeb.children('author').size 
    assert_equal 1, dataOnTheWeb.children('et-al').size 
  end

  def test_1_1_9_7
    # =begin xquery
    # <bib>
    #   {
    #     for $b in doc("http://bstore1.example.com/bib.xml")//book
    #     where $b/publisher = "Addison-Wesley" and $b/@year > 1991
    #     order by $b/title
    #     return
    #         <book>
    #             { $b/@year }
    #             { $b/title }
    #         </book>
    #   }
    # </bib> 
    # =end

    result = XDocument.new(
      XElement.new('bib',
        XQuery.from(XDocument.open(@bib).xpath('//book')) do
          where { | book |
            book.child('publisher').value == 'Addison-Wesley' and
            book.attribute('year').value.to_i > 1991
          }
          order_by { | book |
            book.child('title').value
          }
          select { | book |
            XElement.new('book',
              book.attribute('year'),
              book.child('title')
            )
          }
        end
      )
    )

    assert_equal 'Advanced Programming in the Unix environment',
      result.xpath('//title[position() = 1]').only.value

    assert_equal 'TCP/IP Illustrated',
      result.xpath('//title[position() = 2]').only.value
  end
   
  def test_1_1_9_9
    # =begin xquery
    # <results>
    #   {
    #     for $t in doc("books.xml")//(chapter | section)/title
    #     where contains($t/text(), "XML")
    #     return $t
    #   }
    # </results> 
    # =end

    # NOTE: I don't support location path begins with union expression... anyway
    result = XElement.new('result',
      XQuery.from(XDocument.open(@book).xpath('//chapter/title | //section/title')) do
        where { | title | title.value.include?('XML') }
      end
    )

    assert_equal 2, result.xpath('//title').size
    result.xpath('//title').each do | title |
      assert_equal true, title.value.include?('XML')
    end
  end

  def test_1_1_9_10
    # =begin xquery
    # <results>
    #   {
    #     let $doc := doc("prices.xml")
    #     for $t in distinct-values($doc//book/title)
    #     let $p := $doc//book[title = $t]/price
    #     return
    #       <minprice title="{ $t }">
    #         <price>{ min($p) }</price>
    #       </minprice>
    #   }
    # </results> 
    # =end
   
    doc = XDocument.open(@prices)
    result = XElement.new('result',
      XQuery.from(doc.xpath('distinct-values(//book/title)')) do
        select do | title |
          minprice = doc.xpath("min(//book[title = '#{title}']/price)")
          XElement.new('minprice',
            XAttribute.new('title', title),
            XElement.new('price', minprice)
          )
        end
      end
    )

    assert_equal 34.95, result.xpath('/minprice[@title = "Data on the Web"]/price').only.to_n
    assert_equal 34.95, result.xpath('number(/minprice[@title = "Data on the Web"]/price)')
  end
    
end
