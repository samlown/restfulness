require 'spec_helper'

describe Restfulness::Headers::Accept do

  let :klass do
    Restfulness::Headers::Accept
  end

  describe "initialization" do

    it "should work without string" do
      obj = klass.new
      expect(obj.media_types).to be_empty
    end

    it "should parse a basic string" do
      obj = klass.new("application/json")
      expect(obj.media_types.first.to_s).to eql("application/json")
    end

  end

  describe "parsing" do

    it "should parse array of media types" do
      obj = klass.new("application/json, text/*")
      expect(obj.media_types.length).to eql(2)
      expect(obj.media_types.first.to_s).to eql("application/json")
    end

    it "should parse and re-order media types" do
      obj = klass.new("text/plain, application/json; version=1, text/*")
      expect(obj.media_types.length).to eql(3)
      expect(obj.media_types.first.to_s).to eql("application/json;version=1")
      expect(obj.media_types.last.to_s).to eql("text/*")
    end

  end

  describe "#version" do
    it "should attempt to provide version" do
      obj = klass.new("text/plain, application/json; version=1, text/*")
      expect(obj.version).to eql("1")
    end
  end

  describe "#json?" do
    it "should confirm if content includes json" do
      obj = klass.new("text/plain, application/json; version=1, text/*")
      expect(obj.json?).to be_true
    end
    it "should confirm if json not accepted" do
      obj = klass.new("text/plain, text/*")
      expect(obj.json?).to be_false
    end
  end


  describe "#xml?" do
    it "should confirm if content includes xml" do
      obj = klass.new("text/plain, application/xml; version=1, text/*")
      expect(obj.xml?).to be_true
    end
    it "should confirm if json not accepted" do
      obj = klass.new("text/plain, application/json, text/*")
      expect(obj.xml?).to be_false
    end
  end

end
