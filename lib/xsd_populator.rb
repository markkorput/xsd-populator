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
    target_el = xsd_reader

    if options[:element]
      [options[:element]].flatten.compact.each do |el_name|
        target_el = target_el[el_name]
      end
    end

    if target_el == xsd_reader
      # default: just take the first defined element
      target_el = xsd_reader.elements.first

      # log a warning message, informing that we disregard the other elements
      if target_el && xsd_reader.elements.length > 1
        logger.info "XsdPopulator#populate_xml - Multiple root-level element definitions found in XSD schema, only processing the first one (#{target_el.name})"
      end
    elsif target_el.nil?
      logger.warn "XsdPopulator#populate_xml - Specified element (#{options[:element].inspect}) not found, aborting"
      return nil
    else
      logger.info "XsdPopulator#populate_xml - Starting at specified element: #{target_el.name}"
    end

    # no element definition found? abort with warning
    if target_el.nil?
      logger.warn 'XsdPopulator#populate_xml - No element definitions found in XSD schema, aborting'
      return nil
    end

    xml = Builder::XmlMarkup.new(:ident => 2)
    xml.instruct!

    build_element(xml, target_el)

    return xml.target!
  end


  def build_element(xml, element, provider = self.provider, stack = [])
    content_data = provider.nil? ? nil : provider.try_take(stack + [element.name])

    # TODO; more sophisticated recursion detection;
    # multiple elements of the same name should be able
    # to occur insid the stack
    if stack.include?(element.name)
      logger.warn("XsdPopulator#build_element aborting because of potential endless recursion\nCurrent element: #{element.name}\nstack: #{stack.inspect}")
      return
    end

    logger.debug("XsdPopulator#build_element element: #{element.name}, stack: #{stack.inspect}")

    if element.multiple_allowed?
      xml.comment!("Multiple instances of #{element.name} allowed here")
    end

    attributes_hash = element.attributes.inject({}) do |result, attribute|
      attribute_data = provider.try_take(stack + [element.name, "@#{attribute.name}"])
      result.merge(attribute.name => attribute_data)
    end

    if element.child_elements?  
      xml.tag!(element.name, attributes_hash) do
        element.elements.each do |child|
          build_element(xml, child, provider, stack + [element.name])
        end
      end
    else
      xml.tag!(element.name, content_data, attributes_hash)
    end
  end
end # class XsdPopulator

