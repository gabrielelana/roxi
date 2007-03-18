require 'open-uri'

module ROXI

  module Loader
    
    def string(string)
      doc = XParser.new(string).build
      if block_given?
        return (yield doc)
      end
      return doc
    end

    def open(path)
      doc = string(IO.read(path))
      if block_given?
        return (yield doc)
      end
      return doc
    end

    def uri(uri)
      doc = string(open(uri))
      if block_given?
        return (yield doc)
      end
      return doc
    end

  end

end
