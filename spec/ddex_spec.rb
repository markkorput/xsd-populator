require File.dirname(__FILE__) + '/spec_helper'

require 'ddex_provider'

describe DdexProvider::MessageHeaderProvider do

  before :all do
    @provider = DdexProvider::MessageHeaderProvider.new
  end

  it 'provides MessageHeader xml information' do
    expect(@provider.take(['MessageHeader', '@LanguageAndScriptCode'])).to eq 'NL'
    expect(@provider.take(['MessageHeader', 'MessageThreadId'])).to eq '123'
    expect(@provider.take(['MessageHeader', 'MessageSender', 'PartyId'])).to eq 404
  end
end

describe 'DdexProvider' do
  before :all do
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    @provider = DdexProvider::MessageHeaderProvider.new(:logger => @logger)
    @xsd_reader = XsdReader::XML.new(:xsd_file => File.expand_path(File.join(File.dirname(__FILE__), 'examples', 'ddex-ern-v36.xsd')))
    @populator = XsdPopulator.new(:xsd_reader => @xsd_reader, :data_provider => @provider, :element => ['NewReleaseMessage', 'MessageHeader'], :logger => @logger)
  end

  it "uses provider data to populate the xsd schema" do
    doc = Nokogiri.XML(@populator.populated_xml)
    expect(doc.root.name).to eq 'MessageHeader'
    expect(doc.root.at('MessageThreadId').text).to eq '123'
    expect(doc.root.attributes['LanguageAndScriptCode'].value).to eq 'NL'
    expect(doc.root.at('MessageSender/PartyId').text).to eq '404'
    expect(doc.root.at('MessageSender').attributes['LanguageAndScriptCode'].value).to eq 'EN'
  end

end # describe 'DdexProvider'
