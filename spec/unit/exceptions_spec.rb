require 'spec_helper'

describe Restfulness::HTTPException do

  describe "#initialize" do
    it "should assign variables" do
      obj = Restfulness::HTTPException.new(200, "payload", :message => 'foo', :headers => {})
      expect(obj.status).to eql(200)
      expect(obj.payload).to eql("payload")
      expect(obj.message).to eql('foo')
      expect(obj.headers).to eql({})
    end

    it "should use status status for message if none provided" do
      obj = Restfulness::HTTPException.new(200, "payload")
      expect(obj.message).to eql('OK')
    end
  end


end
