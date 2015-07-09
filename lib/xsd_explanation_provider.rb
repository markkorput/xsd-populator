require 'data_provider'

class XsdExplanationProvider
  include DataProvider::Base

  provider_missing do
    raise 'XsdExplanationProvider needs an xsd reader' if (reader = get_data(:xsd_reader)).nil?

    logger.debug "XsdExplanationProvider got provider id: #{missing_provider}"
    item = reader[missing_provider]

    if item.is_a?(XsdReader::Attribute)
      item.type
    elsif item.is_a?(XsdReader::Element) && item.child_elements?
      # return self, the data provider, so the populator can continue with the child elements
      self
    elsif item
      if item.complex_type && item.complex_type.simple_content && item.complex_type.simple_content.extension
        item.complex_type.simple_content.extension.base
      else
        item.type
      end
    else
      logger.warn "XsdExplanationProvider could not find XSD information for provider `#{missing_provider.inspect}` in XSD file `#{reader.options[:xsd_file]}`"
      nil
    end
  end
end # class XsdExplanationProvider