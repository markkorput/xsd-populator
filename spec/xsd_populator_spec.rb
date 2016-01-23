require File.dirname(__FILE__) + '/spec_helper'

describe XsdPopulator do
  let(:xsd_reader){
    XsdReader::XML.new(:xsd_file => File.expand_path(File.join(File.dirname(__FILE__), 'examples', 'ddex-ern-v36.xsd')))
  }

  let(:logger){
    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN
    logger    
  }

  let(:populator){
    XsdPopulator.new(:reader => xsd_reader, :logger => logger)
  }

  describe "#configure" do
    it "lets you change the configuration options at runtime" do
      expect(populator.xsd_reader).to eq xsd_reader
      expect(populator.logger).to eq logger
      expect(populator.options[:relative_provider]).to eq nil
      # save current configuration
      old_options = populator.options.merge(:relative_provider => nil)
      # reconfigure with invalid data
      populator.configure({:reader => :dummy, :logger => :lagger, :relative_provider => :absolutely})
      # some assertion
      expect(populator.xsd_reader).to eq :dummy
      expect(populator.logger).to eq :lagger
      expect(populator.options[:relative_provider]).to eq :absolutely
      # restore configuration
      populator.configure old_options
      # verify 
      expect(populator.xsd_reader).to eq xsd_reader
      expect(populator.logger).to eq logger
      expect(populator.options[:relative_provider]).to eq nil
    end
  end

  describe "#uncache" do
    it "lets you clear the populated_xml cache" do
      # first create a dummy cache, because producing the full XML will take too much time
      populator.instance_variable_set('@populated_xml', :dummy_value)
      # verify the above instance variable is used to cache populaed_xml
      expect(populator.populated_xml).to eq :dummy_value
      # do it!
      populator.uncache
      # verify the cache instance var is clear
      expect(populator.instance_variable_get('@populated_xml')).to eq nil
    end
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
end

describe "XsdPopulator for partial layouts" do
  let(:xsd_reader){
    XsdReader::XML.new(:xsd_file => File.expand_path(File.join(File.dirname(__FILE__), 'examples', 'ddex-ern-v36.xsd')))
  }

  let(:logger){
    logger = Logger.new(STDOUT)
    logger.level = Logger::WARN
    logger    
  }

  let(:populator){
    XsdPopulator.new({
      :element => ['NewReleaseMessage', 'MessageHeader'],
      :reader=> xsd_reader,
      :logger => logger,
      :strategy => :complete
    })
  }

  it "lets you specify any specific element as root element at initialization" do
    doc = Nokogiri.XML(populator.populated_xml)
    expect(doc.root.name).to eq 'MessageHeader'
    expect(doc.root.element_children.map(&:name)).to eq ["MessageThreadId", "MessageId", "MessageFileName", "MessageSender", "SentOnBehalfOf", "MessageRecipient", "MessageCreatedDateTime", "MessageAuditTrail", "Comment", "MessageControlType"]
    expect(doc.root.at('MessageSender').at('PartyName').at('FullName').attributes['LanguageAndScriptCode'].value).to eq "xs:string"
    expect(doc.root.at('MessageSender').at('PartyName').at('FullNameAsciiTranscribed').attributes).to eq({})
  end

  it "lets you specify any specific element to populate" do
    xml = populator.populate_element([:NewReleaseMessage, :MessageHeader, :MessageSender])
    doc = Nokogiri.XML(xml)
    expect(doc.root.name).to eq 'MessageSender'
    expect(doc.root.element_children.map(&:name)).to eq ['PartyId', 'PartyName', 'TradingName']
  end

  describe ':relative_provider option' do
    class RelativeProviderTester
      include DataProvider::Base

      provides({
        # for default/full stsack strategy
        ['NewReleaseMessage', 'MessageHeader', 'MessageId'] => 'Full ID',
        # for :relative_provider => true strategies with MessageHeader as root element
        ['MessageHeader', 'MessageId'] => 'Relative Version1',
        # for :relative_provider => true strategies with MessageId as root element
        ['MessageId'] => 'Relative Version2'
      })
    end

    it "by default uses the full stack for provider ids" do
      populator.configure(:provider => RelativeProviderTester.new)
      expect(Nokogiri.XML(populator.populated_xml).at('/MessageHeader/MessageId').text).to eq 'Full ID'
      expect(Nokogiri.XML(populator.populate_element(['NewReleaseMessage', 'MessageHeader', 'MessageId'])).at('/MessageId').text).to eq 'Full ID'
    end

    it "uses 'relative' provider ids when the :relative_provider option is true" do
      populator.configure(:provider => RelativeProviderTester.new, :relative_provider => true)
      # MessageHeader is root element
      expect(Nokogiri.XML(populator.populated_xml).at('/MessageHeader/MessageId').text).to eq 'Relative Version1'
      # MessageId is root element
      expect(Nokogiri.XML(populator.populate_element(['NewReleaseMessage', 'MessageHeader', 'MessageId'])).at('/MessageId').text).to eq 'Relative Version2'
    end
  end

  describe XsdPopulator::ElementNotFoundException do
    it 'is thrown when a specified root element cannot be found' do
      expect{ populator.populate_element('InvalidNode') }.to raise_error(XsdPopulator::ElementNotFoundException)
      pop = XsdPopulator.new(:xsd_reader => xsd_reader, :element => ['NewReleaseMessage', 'Foo'], :logger => logger)
      expect{pop.populated_xml}.to raise_error(XsdPopulator::ElementNotFoundException)
    end
  end

  describe :strategy do
    class StrategyProvider
      include DataProvider::Base

      provides({
        ['NewReleaseMessage', 'DealList', 'ReleaseDeal'] => 'Invalid value; ReleaseDeal is a complex node with child-nodes, it should get a DataProvider, not a string',
        ['NewReleaseMessage', 'ReleaseList'] => 'Invalid again',
        ['NewReleaseMessage', 'ResourceList'] => StrategyProvider.new,
        ['NewReleaseMessage', 'WorkList', 'MusicalWork', 'MusicalWorkId'] => lambda{ [StrategyProvider.new] * 3 },
        ['NewReleaseMessage', 'MessageHeader', 'SentOnBehalfOf', '@LanguageAndScriptCode'] => 'UK'
      })
    end

    let(:populator){
      XsdPopulator.new({
        # :element => ['NewReleaseMessage', 'MessageHeader'], # We're going for 'FULL' render this time 
        :reader => xsd_reader,
        :provider => StrategyProvider.new,
        :logger => logger
      })
    }

    it "defaults to the :smart strategy which doesn't add nodes for which no (valid) data is provided, unless there are providers available for any its offspring nodes" do
      xml = populator.populated_xml
      doc = Nokogiri.XML(xml)
      # There's a provider available for ReleaseDeal, an offspring of DealList, and
      # even though it will return invalid data, it will still cause the DealList node to be created
      expect(doc.search("/NewReleaseMessage/DealList").length).to eq 1
      expect(doc.search("/NewReleaseMessage/DealList/ReleaseDeal").length).to eq 0
      # There is a provider for ReleaseList itself, but it returns invalid data; it will not be created
      expect(doc.search("/NewReleaseMessage/ReleaseList").length).to eq 0
      # There is a provider with valid data (a DataProvider object) for ResourceList, it will be created
      expect(doc.search("/NewReleaseMessage/ResourceList").length).to eq 1
      # There is no data provider for WorkList, but there is for one of it descendents so it's created
      expect(doc.search("/NewReleaseMessage/WorkList").length).to eq 1
      # for MusicalWorkId multiple data providers are provided,
      # so multiple nodes will be created. All of them will be empty though...
      expect(doc.search("/NewReleaseMessage/WorkList/MusicalWork/MusicalWorkId").map{|mw| mw.element_children.length}).to eq [0]*3
    end

    it "adds empty simple nodes when :strategy is :all_simple_elements" do
      populator.configure(:strategy => :nil_to_empty)
      doc = Nokogiri.XML(xml = populator.populated_xml)
      expect(doc.search("/NewReleaseMessage/DealList").length).to eq 1 # jsut like 
      expect(doc.search("/NewReleaseMessage/DealList/ReleaseDeal").length).to eq 0
      expect(doc.search("/NewReleaseMessage/ReleaseList").length).to eq 0
      expect(doc.search("/NewReleaseMessage/ResourceList").length).to eq 1
      expect(doc.search("/NewReleaseMessage/WorkList").length).to eq 1
      expect(doc.search("/NewReleaseMessage/WorkList/MusicalWork/MusicalWorkId").map{|mw| mw.element_children.length}).to eq [4]*3
    end

    it "builds all the nodes it can find if the :strategy option is set to :complete" do
      populator.configure(:strategy => :complete, :element => ['NewReleaseMessage', 'WorkList'])
      doc = Nokogiri.XML(xml = populator.populated_xml)
      expect(doc.search("/WorkList").length).to eq 1
      expect(doc.search("/WorkList/MusicalWork/MusicalWorkId").map{|n| n.search("./ISWC").length}).to eq [1]*3
    end

    it "by default doesn't add provider-less attributes" do
      xml = populator.populated_xml
      doc = Nokogiri.XML(xml)
      expect(doc.at("/NewReleaseMessage").attributes['MessageSchemaVersionId'].value).to eq '' # required attribute
      expect(doc.at("/NewReleaseMessage").attributes['ReleaseProfileVersionId']).to eq nil
      expect(doc.at("/NewReleaseMessage").attributes['LanguageAndScriptCode']).to eq nil
      expect(doc.at("/NewReleaseMessage").attributes['LanguageAndScriptCode']).to eq nil
      expect(doc.at("/NewReleaseMessage/MessageHeader").attributes['LanguageAndScriptCode']).to eq nil
      expect(doc.at("/NewReleaseMessage/MessageHeader/SentOnBehalfOf").attributes['LanguageAndScriptCode'].value).to eq 'UK'
    end
  end

  describe 'flexible recursion protection' do
    it 'allows a couple of repetitions by default' do
      xml = populator.populate_element(['NewReleaseMessage', 'ResourceList', 'SoundRecording', 'SoundRecordingDetailsByTerritory', 'TechnicalSoundRecordingDetails', 'File'])
      doc = Nokogiri.XML(xml)
      expect(doc.at('/File/HashSum/HashSum')).to_not eq nil
      expect(doc.at('/File/HashSum/HashSum').text).to eq 'xs:string'
    end
  end

  describe 'provider data for attributes' do
    class FileProvider
      include DataProvider::Base

      # returns two datap provider, each with custom data for the TitleType attribute provider
      provider ['NewReleaseMessage', 'ResourceList', 'SoundRecording', 'SoundRecordingDetailsByTerritory', 'Title'] do
        [
          add_data(:title_type => 'typeA'),
          add_data(:title_type => 'typeB')
        ]
      end

      # the data provided by the above provider should be avialable in the provider below
      provider ['NewReleaseMessage', 'ResourceList', 'SoundRecording', 'SoundRecordingDetailsByTerritory', 'Title', '@TitleType'] do
        get_data(:title_type)
      end
    end

    it "uses provided data for an element's attribute providers" do
    populator
      populator.configure(:provider => FileProvider.new)
      xml = populator.populate_element(['NewReleaseMessage', 'ResourceList', 'SoundRecording', 'SoundRecordingDetailsByTerritory'])
      doc = Nokogiri.XML(xml)
      expect(doc.search('/SoundRecordingDetailsByTerritory/Title').length).to eq 2
      expect(doc.search('/SoundRecordingDetailsByTerritory/Title').map{|node| node.attributes['TitleType'].value}).to eq ['typeA', 'typeB']
    end
  end

  describe ':builder option' do
    let(:builder){
      b = Builder::XmlMarkup.new(:indent => 2)
      b.instruct!
      b
    }

    it 'lets you populate XML into an existing builder instance' do
      # create two levels of arbitrary xml nodes
      builder.genericRootNode do |xml|
        xml.genericSubNode do |xml|
          # insert the DDEX MessageSender (with nested content) inside our generic XML
          populator.populate(:builder => xml, :element => ['NewReleaseMessage', 'MessageHeader', 'MessageSender'])
        end
      end

      # verify our generic XML layout contains the MessageSender part of the DDEX xml
      xml_string = builder.target!
      doc = Nokogiri.XML(xml_string)
      expect(doc.search('//genericRootNode/genericSubNode/MessageSender/PartyName/FullName').length).to eq 1
    end
  end

  describe "full stack traversal" do
    class FullStackProvider
      include DataProvider::Base

      provider ['NewReleaseMessage'] do
        self.add_data!(:party_id => 'NewReleaseID__')
      end

      provider ['NewReleaseMessage', 'MessageHeader', 'MessageId'] do
        self.get_data(:party_id) || 'ID-Missing'
      end
    end

    let(:populator){
      XsdPopulator.new({
        :element => ['NewReleaseMessage', 'MessageHeader'],
        :reader=> xsd_reader,
        :logger => logger,
        :strategy => :complete,
        :provider => FullStackProvider.new
      })
    }

    let(:doc){
      Nokogiri.XML(populator.populated_xml)
    }

    it "executes the data providers for the omitted parent elements" do
      expect(doc.at('/MessageHeader/MessageId').inner_text).to eq 'NewReleaseID__'
    end
  end
end