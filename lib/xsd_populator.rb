require 'bundler/setup'
require 'builder'
require 'xsd_reader'
require 'xsd_explanation_provider'

class XsdPopulator

  class ElementNotFoundException < Exception
  end

  class Informer
    attr_reader :options

    def initialize(_opts = {})
      @options = _opts || {}
    end

    def skip?
      options[:skip] == true
    end
  end # class Informer

  attr_reader :options

  def initialize(_opts = {})
    configure _opts
  end

  def configure _opts = {}
    @options = (@options || {}).merge(_opts.is_a?(Hash) ? _opts : {})
    # remove some cached values
    @logger = nil if _opts[:logger]
    @xsd_reader = nil if _opts[:xsd_reader] || _opts[:reader]
    uncache if _opts[:strategy]
  end

  def uncache
    @populated_xml = nil
  end

  def logger
    return @logger || options[:logger] if @logger || options[:logger]
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN
    return @logger
  end

  def xsd_file
    options[:xsd_file] || options[:xsd]
  end

  def xsd_reader
    @xsd_reader ||= options[:xsd_reader] || options[:reader] || (xsd_file.nil? ? nil : XsdReader::XML.new(:xsd_file => xsd_file, :logger => logger))
  end

  alias :reader :xsd_reader

  def provider
    options[:provider] || options[:data_provider] || default_provider
  end

  def default_provider
    @default_provider ||= XsdExplanationProvider.new(:data => {:xsd_reader => xsd_reader}, :logger => logger)
  end

  def populated_xml
    @populated_xml ||= populate_xml
  end

  def populate_element(element_specifier = nil)
    element_specifier.nil? ? populated_xml : populate_xml(element_specifier)
  end

  def write_file(path)
    # logger.debug "XsdPopulator#write_file to: #{path}"
    File.write(path, populated_xml)
  end

  def max_recursion
    options[:max_recursion] || 3
  end

  private

  def populate_xml(element_specifier = nil)
    if (root_el = root_xsd_element(element_specifier)).nil?
      logger.warn "Couldn't find element definition, aborting"
      return nil
    end

    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!

    stack = options[:relative_provider] == true ? [] : [element_specifier || options[:element]].flatten.compact
    stack.pop
    build_element(xml, root_el, self.provider, stack)

    return xml.target!
  end

  def stack_recursion_count(stack = [])
    stack.select{|el| el == stack.last}.length - 1
  end

  def build_element(xml, element, provider = self.provider, stack = [])
    # TODO; more sophisticated recursion detection;
    # multiple elements of the same name should be able
    # to occur insid the stack
    if stack_recursion_count(stack + [element.name]) > max_recursion
      logger.warn("XsdPopulator#build_element aborting because of potential endless recursion\n - Current element: #{element.name}\n - stack: #{stack.inspect}")
      return
    end

    # let's log positive stuff as well
    logger.debug("XsdPopulator#build_element element: #{element.name}, stack: #{stack.inspect}")

    # get node content data from provider
    content_data = provider.nil? ? nil : provider.try_take(stack + [element.name])
    # get attributes content from the provider
    attributes_data_hash = nil

    if explain_xml? && element.multiple_allowed?
      xml.comment!("Multiple instances of #{element.name} allowed here")
    end 

    # just log a warning if we got an array value for an element that is not allowed
    # to occurs multiple times according to the XSD schema (but still allow data provider to generate the xml)
    if content_data.is_a?(Array) && !element.multiple_allowed?
      logger.warn("Got array value (provider id: #{(stack + [element.name]).inspect}) but element definition doesn't allow multiple instances")
    end

    # make sure it's an array
    content_data = [content_data].flatten # if element.multiple_allowed? && content_data.is_a?(Array)
    # NOTE: this doesn't array-values for single elements, which we don't support (would be turned into a string anway)

    content_data.each_with_index do |node_content, idx|
      # let's see if the provided data is good for building this node, according to the current strategy
      next if !build?(element, provider, stack, :content => node_content)

      # value for current element is a content provider?
      if node_content.respond_to?(:try_take)
        attributes_hash = attributes_for(element, node_content.respond_to?(:take) ? node_content : provider, stack)
      else
        attributes_data_hash ||= attributes_data_hash_for(element, provider, stack)
        attributes_hash = attributes_hash_for_index(attributes_data_hash, idx)
      end

      # simple node; name, value, attributes
      if !element.child_elements?
        xml.tag!(element.name, node_content, attributes_hash)
        next
      end

      # complex node
      if node_content.respond_to?(:try_take)
        child_provider = node_content
      else
        logger.warn "Got non-nil and non-provider value for element with child elements (value: #{node_content}, element: #{element.name}, stack: #{stack.inspect})" if node_content
        # strategy dictates to continue; just use the current element's provider for its children
        child_provider = provider
      end

      # create complex node
      xml.tag!(element.name, attributes_hash) do
        # loop over all child node definitions
        element.elements.each do |child|
          # this method call itself recursively for every child node definition of the current element
          build_element(xml, child, child_provider, stack + [element.name])
        end
      end
    end
  end


  #
  # Attribute data
  #

  def attributes_data_hash_for(element, provider, stack)
    element.attributes.inject({}) do |result, attribute|
      attribute_data = provider.nil? ? nil : provider.try_take(stack + [element.name, "@#{attribute.name}"])  
      # attribute_data ||= attribute.type if provider.nil? # assume demo xml
      if add_attribute?(attribute, provider, stack, :content => attribute_data)
        result.merge(attribute.name => attribute_data)
      else
        result
      end
    end
  end

  def attribute_value_for_index(values, idx)
    # if the provided attribute content is an array, just use the appropriate element
    # if the array does not have enough element, this will default to nil
    # if values is not an array, just always use its singular value
    values.is_a?(Array) ? values[idx] : values
  end

  def attributes_hash_for_index(attribute_data_hash, idx)
    # each of the attribute values can be an array as well. If not,
    # we'll just use it's singular value for all instances of this node
    # if there 
    current_attrs = attribute_data_hash.to_a.inject({}) do |result, key_value|
      key = key_value[0]
      value = key_value[1]
      logger.warn "XsdPopulator#attributes_hash_for_index - got an array with insufficient values for attribute `#{key}`. Attribute data hash: #{attribute_data_hash}, index: #{idx}" if value.is_a?(Array) && value.length <= idx
      attr_value = attribute_value_for_index(value, idx)
      result.merge(key => attr_value)
    end
  end

  def attributes_for(element, provider, stack)
    element.attributes.inject({}) do |result, attribute|
      attribute_data = provider.nil? ? nil : provider.try_take(stack + [element.name, "@#{attribute.name}"])  
      # attribute_data ||= attribute.type if provider.nil? # assume demo xml
      if add_attribute?(attribute, provider, stack, :content => attribute_data)
        result.merge(attribute.name => attribute_data)
      else
        result
      end
    end
  end

  #
  # Root element
  #
  def specified_xsd_element(specifier = nil)
    # nothing specified
    return nil if (specifier || options[:element]).nil?
    # find specified element
    el = xsd_reader[[(specifier || options[:element])].flatten.compact]
    raise ElementNotFoundException.new(:message => "Could not find specified root element (#{(specifier || options[:element]).inspect}).") if el.nil?
    # log warning if specified element not found
    logger.warn "XsdPopulator#populate_xml - Specified element (#{options[:element].inspect}) not found, reverting to default" if el.nil?
    # return result
    return el
  end

  def root_xsd_element(specifier = nil)
    el = specified_xsd_element(specifier)

    # no element specified? (or found)
    if el
      # log inform notice that we're using the explicitly specified element
      logger.info "XsdPopulator#populate_xml - Starting at specified element: #{el.name}"
    else
      # default: just take the first defined element
      el ||= xsd_reader.elements.first

      # if there are multiple root-level elements in the xsd, let the user know, we're only processing the fist one
      if el && xsd_reader.elements.length > 1
        logger.info "XsdPopulator#populate_xml - Multiple root-level element definitions found in XSD schema, only processing the first one (#{el.name})"
      end
    end

    return el
  end

  #
  # Strategy
  #
  public

  def strategy
    options[:strategy] || (explain_xml? ? :complete : :smart)
  end

  def explain_xml?
    provider == default_provider
  end

  def build_node_without_provider?
    strategy == :complete
  end

  def add_simple_nodes_without_data?
    strategy == :nil_to_empty || strategy == :complete
  end

  def build?(element, provider, stack, opts = {})
    content = opts[:content] || provider.try_take([stack, element.name].flatten.compact)

    # we got an Informer object that tells us explicitly to skip this node? Yes sir.
    return false if content.is_a?(Informer) && content.skip?

    # For comlex nodes we need either;
    # - a data provider or
    # - explicit confirmation to build without providers or
    # - providers available for offspring elements
    if element.child_elements? 
      return content.respond_to?(:try_take) || build_node_without_provider? || provider.has_providers_with_scope?(stack + [element.name])
    end

    # we got a non-nil value for a simple node? Go ahead
    return true if content || add_simple_nodes_without_data?

    return false

    # !build_node_without_provider? || 
    # return true if provider
  end

  def add_empty_attributes?
    strategy == :nil_to_empty || strategy == :complete
  end

  def add_attribute?(attribute, provider, stack = [], opts = {})
    return true if attribute.required?
    content = opts[:content] || provider.try_take(stack + ["@#{attribute.name}"])
    return (!content.nil?) || add_empty_attributes?
  end
end # class XsdPopulator

