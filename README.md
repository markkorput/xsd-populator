# xsd-populator
A Ruby gem to produce XML data from XSD schemas and DataProvider objects.

See the data-provider gem: [https://github.com/markkorput/data-provider](https://github.com/markkorput/data-provider)

[![Build Status](https://travis-ci.org/markkorput/xsd-populator.svg)](https://travis-ci.org/markkorput/xsd-populator)



## Installation


Rubygems:

```
gem install xsd-populator
```

Bundler: 

```ruby
gem 'xsd-populator'
````

## Examples

Load xsd
```ruby
require 'xsd_populator'
reader = XsdPopulator.new(:xsd => 'ddex-ern-v36.xsd')
reader.populated_xml # => XML-string
```

Not that in this minimal implementation, no custom data provider is given to the populator, causing it to use the default internal 'XsdExplanationProvider', which produces explanatory XML.

For this [elaborate example XSD](https://github.com/markkorput/xsd-populator/blob/master/spec/examples/ddex-ern-v36.xsd), this would produce [this xml](https://github.com/markkorput/xsd-populator/blob/master/spec/examples/ddex-ern-v36-NewReleaseMessage.xml)


### Using actual custom data providers

In practice, you'd implement a custom DataProvider class (see the [data-provider gem](https://github.com/markkorput/data-provider)) and pass it into the XsdPopulator.

```ruby
require 'xsd_populator'

data_provider = CustomDataProvider.new(:some => 'data')
reader = XsdPopulator.new(:xsd => 'ddex-ern-v36.xsd', :provider => data_provider)
reader.populated_xml # => XML-string
```

### Producing specific parts of an XML structure

In case you want to produce only a specific part of an XML hierarchy, you can specify an element when initializing the populator object:

```ruby
reader = XsdPopulator.new(:xsd => 'ddex-ern-v36.xsd', :element => ['NewReleaseMessage', 'MessageHeader'])
reader.populated_xml # => XML-string containing only the part
```

The :element option takes an array-value representing an element's XPath (in this case that XPath is /NewReleaseMessage/MessageHeader). The specified element become(s) the root-element(s) in the produced XML.

This example would produce [this XML](https://github.com/markkorput/xsd-populator/blob/master/spec/examples/ddex-ern-v36-MessageHeader.xml)







