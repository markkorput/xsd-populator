require File.dirname(__FILE__) + '/spec_helper'

require 'ddex_provider'

describe DdexProvider::Provider do

  before :all do
    @provider = DdexProvider::Provider.new
  end

  it 'provides MessageHeader xml information' do
    expect(@provider.take(['@LanguageAndScriptCode'])).to eq 'NL'
    expect(@provider.take(['MessageThreadId'])).to eq '123'
    expect(@provider.take(['MessageSender', 'PartyId'])).to eq 404
  end
end