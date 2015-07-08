require File.dirname(__FILE__) + '/spec_helper'

describe XsdPopulator do

  before :all do
    # xsd_reader ||= XsdReader::XML.new(:xsd_file => File.expand_path(File.join(File.dirname(__FILE__), 'examples', 'ddex-ern-v36.xsd')))
    @populator = XsdPopulator.new(:xsd_file => File.expand_path(File.join(File.dirname(__FILE__), 'examples', 'ddex-ern-v36.xsd')))
  end

  # # TAKES LONG
  # it "should generate xml without data and include comments" do
  #   expect(doc.root_node.name).to eq 'NewReleaseMessage'
  # end

  # # TAKES LONG
  # it "writes to file" do
  #   @populator.write_file(File.dirname(__FILE__) + '/examples/ddex-ern-v36.xml')
  # end

  # TAKES LONG
  # it "it lets you specify a root-level element" do
  #   populator = XsdPopulator.new(:xsd_reader => @populator.xsd_reader, :element => 'CatalogListMessage')
  #   populator.write_file(File.dirname(__FILE__) + '/examples/ddex-ern-v36-CatalogListMessage2.xml')
  # end

  it "it lets you specify any specific element as root element" do
    populator = XsdPopulator.new(:xsd_reader => @populator.xsd_reader, :element => ['NewReleaseMessage', 'MessageHeader'])
    # populator.write_file(File.dirname(__FILE__) + '/examples/ddex-ern-v36-MessageHeader.xml')
    doc = Nokogiri.XML(populator.populated_xml)
    expect(doc.root.name).to eq 'MessageHeader'
    expect(doc.root.element_children.map(&:name)).to eq ["MessageThreadId", "MessageId", "MessageFileName", "MessageSender", "SentOnBehalfOf", "MessageRecipient", "MessageCreatedDateTime", "MessageAuditTrail", "Comment", "MessageControlType"]
    expect(doc.root.at('MessageSender').at('PartyName').at('FullName').attributes['LanguageAndScriptCode'].value).to eq "xs:string"
    expect(doc.root.at('MessageSender').at('PartyName').at('FullNameAsciiTranscribed').attributes).to eq({})
  end
end
