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

      sum
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

  describe "#take" do
    it 'lets you take data from it' do
      expect(@provider.take(:sum)).to eq 7
    end
  end

  describe "#give" do
    it "lets you give data, creating a new data provider instance" do
      updated_provider = @provider.give :array => [1,80]
      expect(@provider.take(:sum)).to eq 7
      expect(updated_provider.take(:sum)).to eq 81
    end

    it "allows for linked notation" do
      expect(@provider.give(:array => [7, -3]).take(:sum)).to eq 4
    end
  end

  describe "#give!" do
    it "lets you update the current provider with additional data" do
      provider = ProviderClass.new(:array => [1,1,90])
      expect(provider.take(:sum)).to eq 92
      provider.give!(:array => [3,90])
      expect(provider.take(:sum)).to eq 93
    end

    it "allows for linked notation" do
      expect(@provider.give!(:array => [-1, -4]).take(:sum)).to eq -5
    end
  end
end