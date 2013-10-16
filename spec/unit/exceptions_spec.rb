require 'spec_helper'

describe Restfulness::HTTPException do

  describe "#initialize" do
    it "should assign variables" do
      obj = Restfulness::HTTPException.new(200, "payload", :message => 'foo', :headers => {})
      obj.status.should eql(200)
      obj.payload.should eql("payload")
      obj.message.should eql('foo')
      obj.headers.should eql({})
    end

    it "should use status status for message if none provided" do
      obj = Restfulness::HTTPException.new(200, "payload")
      obj.message.should eql('OK')
    end
  end


end
