require 'data_provider'

module DdexProvider

  module MessageSender
    include DataProvider::Base

    provider '@LanguageAndScriptCode' do 'EN' end
    provider 'PartyId' do 404 end

  end # module MessageSender

  module MessageRecipient
    include DataProvider::Base

    # provides multiple party ids; this will result in 3 <PartyId> nodes
    # within the <MessageRecipient> node
    provider 'PartyId' do
      [12, 34, 56]
    end

    # Because the 'PartyId' provides 3 values, 3 nodes will be created
    # because the ['PartyId', '@IsDPID'] provider provides only one value,
    # all 3 PartyId nodes will get the same value for their IsDPID attribute
    provider ['PartyId', '@IsDPID'] do
      'TRUTH'
    end

  end # module MessageRecipient

  module SentOnBehalfOf
    include DataProvider::Base

    # provides multiple party ids; this will result in 3 <PartyId> nodes
    # within the <SentOnBehalfOf> node
    provider 'PartyId' do
      [9,8,7]
    end

    # Because the 'PartyId' provides 3 values, 3 nodes will be created
    # because the ['PartyId', '@IsDPID'] provider provides only two values for the third,
    # nil value will be assumed and a warning will be logged
    provider ['PartyId', '@IsDPID'] do
      ['true', 'false']
    end

  end # module SentOnBehalfOf


  module MessageHeader
    include DataProvider::Base

    provider '@LanguageAndScriptCode' do
      'NL'
    end

    provider 'MessageThreadId' do
      123.to_s
    end

    add_xml_provider MessageSender, :scope => 'MessageSender'
    add_xml_provider SentOnBehalfOf, :scope => 'SentOnBehalfOf'
    add_xml_provider MessageRecipient, :scope => 'MessageRecipient'

    provider ['MessageAuditTrail', 'MessageAuditTrailEvent'] do
      # gives three new data providers with each their own :name
      ['John', 'Billy', 'Bob'].map do |name|
        self.give(:name => name)
      end
    end

    provider ['MessageAuditTrail', 'MessageAuditTrailEvent', 'MessagingPartyDescriptor', 'PartyName', 'FullName'], :requires => [:name] do
      given(:name)
    end

  end # module MessageHeader


  class MessageHeaderProvider
    include DataProvider::Base
    add_xml_provider MessageHeader, :scope => 'MessageHeader'
  end # class Provider

end # module DdexProvider