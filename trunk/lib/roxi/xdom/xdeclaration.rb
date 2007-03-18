
module ROXI
  
  class XDeclaration < XItem

    attr_reader :version, :encoding, :standalone

    def initialize(*args)
      super()
      @version = '1.0'
      @encoding = 'utf-8'
      @standalone = 'yes'
      args.each { | attribute | add(attribute) }
    end

    def append(attribute)
      case attribute.name
      when 'version'
        @version = attribute.value
      when 'encoding'
        @encoding = attribute.value
      when 'standalone'
        @standalone = attribute.value
      end
    end

    def value
      "version=\"#{@version}\" encoding=\"#{@encoding}\" standalone=\"#{@standalone}\""
    end

    alias_method :<<, :append
    alias_method :add, :append

    protected

    def path_name
      '/xml-declaration'
    end

  end

end
