require File.dirname(__FILE__) + '/spec_helper'

describe XsdPopulator::Informer do
  class InformProvider
    include DataProvider::Base

    provides({
    	['NewReleaseMessage', 'MessageHeader'] => XsdPopulator::Informer.new(:skip => true),
    	['NewReleaseMessage', 'MessageHeader', 'MessageId'] => 123,
    	['NewReleaseMessage', 'ResourceList', 'SoundRecording', 'SoundRecordingType'] => XsdPopulator::Informer.content('SuperMegaBox')
  	})
  end

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
      :reader=> xsd_reader,
      :logger => logger,
      :provider => InformProvider.new
    })
  }

  describe "#skip" do
  	it "specifies if the skip flag is enabled" do
  		expect(XsdPopulator::Informer.new(:skip => true).skip?).to eq true
  		expect(XsdPopulator::Informer.new(:skip => false).skip?).to eq false
  	end

  	it "is false by default" do
  		expect(XsdPopulator::Informer.new.skip?).to eq false
  	end
  end

  describe "#attributes?" do
  	it "tells if attributes were explicitly specified" do
  		expect(XsdPopulator::Informer.new(:attributes => {}).attributes?).to eq true
  		expect(XsdPopulator::Informer.new(:attributes => nil).attributes?).to eq true
  		expect(XsdPopulator::Informer.new(:attrs => {}).attributes?).to eq false
  	end

  	it "is false by default" do
  		expect(XsdPopulator::Informer.new.attributes?).to eq false
  	end
  end

  describe "#content?" do
  	it "tells if the informer was explicitly given content" do
  		expect(XsdPopulator::Informer.new(:content => {}).content?).to eq true
  		expect(XsdPopulator::Informer.new(:content => 'Something').content?).to eq true
  		expect(XsdPopulator::Informer.new(:content => nil).content?).to eq true
  	end

  	it "is false by default" do
  		expect(XsdPopulator::Informer.new(:attributes => {}).content?).to eq false
  		expect(XsdPopulator::Informer.new.content?).to eq false
  	end
  end

  describe "#namespace?" do
  	it "tells if namespace information was explicitly specified" do
  		expect(XsdPopulator::Informer.new(:namespace => {}).namespace?).to eq true
  		expect(XsdPopulator::Informer.new(:namespace => 'Something').namespace?).to eq true
  		expect(XsdPopulator::Informer.new(:namespace => nil).namespace?).to eq true
  	end

  	it "is false by default" do
  		expect(XsdPopulator::Informer.new(:attributes => {}).namespace?).to eq false
  		expect(XsdPopulator::Informer.new.namespace?).to eq false
  	end
  end

  describe ":skip" do
	  it "informs the populator to skip an element" do
	    expect(Nokogiri.XML(populator.populated_xml).at('/NewReleaseMessage/MessageHeader')).to eq nil
	  end
	end

	describe ":attributes" do
	  it "informs the populator to explicitly add a set of attributes to an element" do
	    provider_class = Class.new(Object) do
	      include DataProvider::Base

	      provider ['NewReleaseMessage', '@MessageSchemaVersionId']{ '2010/ern-main/32' }

	      provider ['NewReleaseMessage']{
	        XsdPopulator::Informer.new(:attributes => {
	          'xmlns:ern' => 'http://ddex.net/xml/2010/ern-main/32', 
	          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
	          'xsi:schemaLocation' => 'http://ddex.net/xml/2010/ern-main/32 http://ddex.net/xml/2010/ern-main/32/ern-main.xsd'
	        })
	      }

	      provides(['NewReleaseMessage', 'MessageHeader', 'MessageId'] => 123)
	    end

	    populator = XsdPopulator.new({
	      :reader=> xsd_reader,
	      :logger => logger,
	      :provider => provider_class.new
	    })

	    el = Nokogiri.XML(populator.populated_xml).at('NewReleaseMessage')
	    expect(el.attributes['schemaLocation'].value).to eq 'http://ddex.net/xml/2010/ern-main/32 http://ddex.net/xml/2010/ern-main/32/ern-main.xsd'
	    expect(el.attributes['MessageSchemaVersionId'].value).to eq '2010/ern-main/32'
	    expect(el.attributes.keys.length).to eq 2

	    expect(el.namespace_definitions.map{|nsdef| [nsdef.prefix, nsdef.href]}.sort).to eq([
	      ['ern', 'http://ddex.net/xml/2010/ern-main/32'],
	      ['xsi', 'http://www.w3.org/2001/XMLSchema-instance']
	    ])
	  end
	end

	describe ":namespace" do
	  it "informs the populator to prefix a node with a namespace" do
	    provider_class = Class.new(Object) do
	      include DataProvider::Base

	      provider ['NewReleaseMessage']{ XsdPopulator::Informer.new(:namespace => 'ern') }
	      provides(['NewReleaseMessage', 'MessageHeader', 'MessageId'] => 123)
	    end

	    populator = XsdPopulator.new({
	      :reader=> xsd_reader,
	      :logger => logger,
	      :provider => provider_class.new
	    })

	    expect(Nokogiri.XML(populator.populated_xml).root.name).to eq 'ern:NewReleaseMessage'
	  end
	end

	describe ":content" do
		it "informs the populator to use the specified content for the element" do
			expect(Nokogiri.XML(populator.populated_xml).at('/NewReleaseMessage/ResourceList/SoundRecording/SoundRecordingType').text).to eq 'SuperMegaBox'
		end
	end
end