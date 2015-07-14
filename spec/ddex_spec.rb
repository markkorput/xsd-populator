require File.dirname(__FILE__) + '/spec_helper'

require 'ddex_provider'

describe DdexProvider::MessageHeaderProvider do
  let(:logger){
    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN
    logger    
  }

  let(:provider){
    DdexProvider::MessageHeaderProvider.new(:logger => logger)
  }

  it 'provides MessageHeader xml information' do
    expect(provider.take(['MessageHeader', '@LanguageAndScriptCode'])).to eq 'NL'
    expect(provider.take(['MessageHeader', 'MessageThreadId'])).to eq '123'
    expect(provider.take(['MessageHeader', 'MessageSender', 'PartyId'])).to eq 404
  end
end

describe DdexProvider do
  let(:logger){
    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN
    logger    
  }

  let(:provider){
    DdexProvider::MessageHeaderProvider.new(:logger => logger)
  }

  let(:xsd_reader){
    XsdReader::XML.new(:xsd_file => File.expand_path(File.join(File.dirname(__FILE__), 'examples', 'ddex-ern-v36.xsd')), :logger => logger)
  }

  let(:populator){
    XsdPopulator.new(:xsd_reader => xsd_reader, :data_provider => provider, :element => ['NewReleaseMessage', 'MessageHeader'], :relative_provider => true, :logger => logger, :strategy => :complete)
  }

  it "uses provider data to populate the xsd schema" do
    doc = Nokogiri.XML(populator.populated_xml)
    expect(doc.root.name).to eq 'MessageHeader'
    # byebug
    expect(doc.root.at('MessageThreadId').text).to eq '123'
    expect(doc.root.attributes['LanguageAndScriptCode'].value).to eq 'NL'
    expect(doc.root.at('MessageSender/PartyId').text).to eq '404'
    expect(doc.root.at('MessageSender').attributes['LanguageAndScriptCode'].value).to eq 'EN'
    expect(doc.root.search('SentOnBehalfOf/PartyId').map(&:text)).to eq ['9', '8', '7']
    expect(doc.root.search('SentOnBehalfOf/PartyId').map{|node| node.attributes['IsDPID'].value}).to eq ['true', 'false', '']
    expect(doc.root.search('MessageRecipient/PartyId').map(&:text)).to eq ['12', '34', '56']
    expect(doc.root.search('MessageRecipient/PartyId').map{|node| node.attributes['IsDPID'].value}).to eq ['TRUTH']*3
    expect(doc.root.search('MessageAuditTrail/MessageAuditTrailEvent').length).to eq 3
    expect(doc.root.search('MessageAuditTrail/MessageAuditTrailEvent/MessagingPartyDescriptor/PartyName/FullName').map(&:text)).to eq ['John', 'Billy', 'Bob']
  end
end # describe DdexProvider
