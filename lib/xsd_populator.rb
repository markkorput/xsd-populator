require 'bundler/setup'
require 'builder'
require 'xsd_reader'

class XsdPopulator

  attr_reader :options

  def initialize(_opts = {})
    @options = _opts.is_a?(Hash) ? _opts : {}
  end

  def logger
    @logger ||= options[:logger] || Logger.new(STDOUT)
  end

  def xsd_reader
    options[:xsd_reader]
  end

  def provider
    options[:provider] || options[:data_provider]
  end

  def populated_xml
    @populated_xml ||= populate_xml
  end

  def write_file(path)
    # logger.debug "XsdPopulator#write_file to: #{path}"
    File.write(path, populated_xml)
  end

  private

  def populate_xml
    if (root_el = root_xsd_element).nil?
      logger.warn "Couldn't find element definition, aborting"
      return nil
    end

    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!

    build_element(xml, root_el)

    return xml.target!
  end

  def attribute_data_hash_for(element, provider, stack)
    element.attributes.inject({}) do |result, attribute|
      attribute_data = provider.nil? ? nil : provider.try_take(stack + [element.name, "@#{attribute.name}"])  
      attribute_data ||= attribute.type if provider.nil? # assume demo xml
      result.merge(attribute.name => attribute_data)
    end
  end

  def atrribute_value_for_index(values, idx)
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
      attr_value = atrribute_value_for_index(value, idx)
      result.merge(key => attr_value)
    end
  end

  def build_element(xml, element, provider = self.provider, stack = [])
    # TODO; more sophisticated recursion detection;
    # multiple elements of the same name should be able
    # to occur insid the stack
    if stack.include?(element.name)
      logger.warn("XsdPopulator#build_element aborting because of potential endless recursion\nCurrent element: #{element.name}\nstack: #{stack.inspect}")
      return
    end

    logger.debug("XsdPopulator#build_element element: #{element.name}, stack: #{stack.inspect}")
    content_data = provider.nil? ? nil : provider.try_take(stack + [element.name])

    attributes_data_hash = attribute_data_hash_for(element, provider, stack)

    if element.child_elements?  
      xml.tag!(element.name, attributes_data_hash) do
        element.elements.each do |child|
          build_element(xml, child, provider, stack + [element.name])
        end
      end

      return
    end

    if element.multiple_allowed? && content_data.is_a?(Array)
      # turn into array
      content_data = [content_data].flatten

      if provider.nil?
        # no provider, let's assume we're producing an explanatory example XML
        xml.comment!("Multiple instances of #{element.name} allowed here")
      end 
    else
      # make sure it's not an array
      content_data = [content_data.to_s]
    end

    content_data.each_with_index do |dat, idx|
      # # each of the attribute values can be an array as well. If not,
      # # we'll just use it's single values for all instances of this node
      # current_attrs = attributes_hash.to_a.inject({}) do |result, key_value|
      #   key = key_value[0]
      #   value = key_value[1]

      #   result.merge key => if value.is_a?(Array)
      #     if value[idx]
      #       value[idx]
      #     else
      #       content_id = stack + [element.name]
      #       attr_id = content_id + ["@#{key}"]
      #       logger.warn("XsdPopulator#build_element - data provider gave different length arrays for #{content_id.inspect} and #{attr_id.inspect}")
      #       nil
      #     end
      #   else
      #     value
      #   end
      # end
      attribute_hash = attributes_hash_for_index(attributes_data_hash, idx)
      xml.tag!(element.name, dat, attribute_hash)
    end
  end

  def specified_xsd_element
    # nothing specified
    return nil if options[:element].nil?
    # find specified element
    el = xsd_reader[[options[:element]].flatten.compact]
    # log warning if specified element not found
    logger.warn "XsdPopulator#populate_xml - Specified element (#{options[:element].inspect}) not found, reverting to default" if el.nil?
    # return result
    return el
  end

  def root_xsd_element
    el = specified_xsd_element

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

end # class XsdPopulator

