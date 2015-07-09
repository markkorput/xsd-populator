require File.dirname(__FILE__) + '/spec_helper'
require 'xsd_explanation_provider'

describe XsdExplanationProvider do
  let(:logger){
    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN
    logger    
  }

  let(:populator){
    XsdPopulator.new(:xsd_file => File.expand_path(File.join(File.dirname(__FILE__), 'examples', 'ddex-ern-v36.xsd')), :logger => logger)
  }

  let(:provider){
    XsdExplanationProvider.new(:data => {:xsd_reader => populator.xsd_reader})
  }

  it "requires an xsd reader" do
    msg = expect{ XsdExplanationProvider.new.take(:something) }.to raise_error(RuntimeError, 'XsdExplanationProvider needs an xsd reader')
  end

  it "gives itself for complex elements" do
    expect(provider.take('NewReleaseMessage')).to eq provider
    expect(provider.take(['NewReleaseMessage', 'MessageHeader'])).to eq provider
  end

  it "gives the element type for simple elements" do
    expect(provider.take(['NewReleaseMessage', 'MessageHeader', 'MessageId'])).to eq 'xs:string'
  end

  it "gives the attribute type for attributes" do
    expect(provider.take(['NewReleaseMessage', 'MessageHeader', '@LanguageAndScriptCode'])).to eq 'xs:string'
  end

  it "is the default fallback provider for XsdPopulators without a specified provider" do
    expect(populator.provider.class).to eq XsdExplanationProvider
    xml = populator.populate_element(['NewReleaseMessage', 'MessageHeader', 'MessageSender'])
    # puts xml
    doc = Nokogiri.XML(xml)
    expect(doc.at('/MessageSender/PartyId').text).to eq 'xs:string'
    expect(doc.at('/MessageSender').attributes['LanguageAndScriptCode'].value).to eq 'xs:string'

      # PartyId
  end
end # describe XsdExplanationProvider
