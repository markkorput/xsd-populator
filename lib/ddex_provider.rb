require 'data_provider'

module DdexProvider
  module MessageSender
    include DataProvider::Base

    provider '@LanguageAndScriptCode' do 'EN' end
    provider 'PartyId' do 404 end
  end # module MessageSender


  module MessageHeader
    include DataProvider::Base

    provider '@LanguageAndScriptCode' do
      'NL'
    end

    provider 'MessageThreadId' do
      123.to_s
    end

    add_xml_provider MessageSender, :scope => 'MessageSender'
  end # module MessageHeader


  class MessageHeaderProvider
    include DataProvider::Base
    add_xml_provider MessageHeader, :scope => 'MessageHeader'
  end # class Provider

end # module DdexProvider