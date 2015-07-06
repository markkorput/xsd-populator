require File.dirname(__FILE__) + '/spec_helper'

require 'data_provider'

describe DataProvider::Base do

  class ProviderClass
    include DataProvider::Base

    provider :sum, :requires => [:array] do
      sum = 0
      given(:array).each do |number|
        sum += number.to_i
      end
      return sum
    end

  end

  before :all do
    @provider = ProviderClass.new(:array => [1,2,4])
  end

  describe "#has_provider?" do
    it 'provides the has_provider? method' do
      expect(@provider.has_provider?(:sum)).to be true
      expect(@provider.has_provider?(:modulus)).to be false
    end
  end

end