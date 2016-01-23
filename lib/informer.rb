class XsdPopulator
	class Informer
    attr_reader :options

    def initialize(_opts = {})
      @options = _opts || {}
    end

    def skip?
      options[:skip] == true
    end

    def self.skip
      self.new(:skip => true)
    end

    def attributes
      options[:attributes] || {}
    end

    def attributes?
      self.options.keys.include?(:attributes)
    end

    def self.attributes(attrs)
      self.new(:attributes => attrs)
    end

    def namespace
      options[:namespace]
    end

    def namespace?
      options.keys.include?(:namespace)
    end

    def self.namespace(ns)
      self.new(:namespace => ns)
    end

    def content
      options[:content]
    end

    def content?
      self.options.keys.include?(:content)
    end

    def self.content(content)
      self.new(:content => content)
    end
  end # class Informer
end # module XsdPopulator