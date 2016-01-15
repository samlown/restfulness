
require 'spec_helper'

describe Restfulness::Dispatcher do

  describe "#initialize" do
    it "should assign app variable" do
      obj = Restfulness::Dispatcher.new(:foo)
      expect(obj.app).to eql(:foo)
    end
  end


end
