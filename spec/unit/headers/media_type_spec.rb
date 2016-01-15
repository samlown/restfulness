require 'spec_helper'

describe Restfulness::Headers::MediaType do

  let :klass do
    Restfulness::Headers::MediaType
  end

  describe "initialization" do

    it "should be able to except no parameter and set defaults" do
      obj = klass.new
      expect(obj.type).to eql("*")
      expect(obj.subtype).to eql("*")
      expect(obj.parameters).to eql({})
      expect(obj.vendor).to eql("")
      expect(obj.suffix).to eql("")
    end

    it "should handle string and parse" do
      obj = klass.new("application/json")
      expect(obj.type).to eql("application")
      expect(obj.subtype).to eql("json")
    end

  end

  describe "parsing" do

    it "should handle params" do
      obj = klass.new("applcation/json;version=2")
      expect(obj.subtype).to eql('json')
      expect(obj.parameters[:version]).to eql("2")
    end

    it "should handle params with white space" do
      obj = klass.new("applcation/json; version=3")
      expect(obj.subtype).to eql('json')
      expect(obj.parameters[:version]).to eql("3")
    end

    it "should handle multiple params" do
      obj = klass.new("applcation/json;version=2;test=yes")
      expect(obj.subtype).to eql('json')
      expect(obj.parameters[:version]).to eql("2")
      expect(obj.parameters[:test]).to eql("yes")
    end

    it "should handle suffix" do
      obj = klass.new("applcation/xhtml+xml")
      expect(obj.subtype).to eql('xhtml')
      expect(obj.suffix).to eql('xml')
    end

    it "should handle vendor" do
      obj = klass.new("applcation/vnd.example.user; version=3")
      expect(obj.subtype).to eql('user')
      expect(obj.vendor).to eql('example')
      expect(obj.suffix).to eql('')
      expect(obj.parameters[:version]).to eql("3")
    end

    it "should handle vendor with suffix" do
      obj = klass.new("applcation/vnd.example.user+json; version=3")
      expect(obj.subtype).to eql('user')
      expect(obj.vendor).to eql('example')
      expect(obj.suffix).to eql('json')
      expect(obj.parameters[:version]).to eql("3")
    end

    it "should handle vendor with domain" do
      obj = klass.new("applcation/vnd.example.com.user; version=3")
      expect(obj.subtype).to eql('user')
      expect(obj.vendor).to eql('example.com')
      expect(obj.suffix).to eql('')
      expect(obj.parameters[:version]).to eql("3")
    end

  end

  describe "conversion to string" do
    
    it "should handle empty type" do
      obj = klass.new
      expect(obj.to_s).to eql("*/*")
    end

    it "should handle basic type" do
      obj = klass.new
      obj.type = "application"
      obj.subtype = "json"
      expect(obj.to_s).to eql('application/json')
    end

    it "should handle parameter" do
      obj = klass.new
      obj.type = "application"
      obj.subtype = "json"
      obj.parameters[:version] = 1
      expect(obj.to_s).to eql('application/json;version=1')
    end

    it "should handle multiple parameters" do
      obj = klass.new
      obj.type = "application"
      obj.subtype = "json"
      obj.parameters[:version] = 1
      obj.parameters[:charset] = "UTF-8"
      expect(obj.to_s).to eql('application/json;version=1;charset=UTF-8')
    end

    it "should handle suffix" do
      obj = klass.new
      obj.type = "application"
      obj.subtype = "xhtml"
      obj.suffix = "xml"
      expect(obj.to_s).to eql('application/xhtml+xml')
    end

    it "should handle vendor" do
      obj = klass.new
      obj.type = "application"
      obj.vendor = "example.com"
      obj.subtype = "user"
      expect(obj.to_s).to eql('application/vnd.example.com.user')
    end

    it "should handle vendor with suffix" do
      obj = klass.new
      obj.type = "application"
      obj.vendor = "example.com"
      obj.subtype = "user"
      obj.suffix = "json"
      expect(obj.to_s).to eql('application/vnd.example.com.user+json')
    end

    it "should handle vendor with suffix and params" do
      obj = klass.new
      obj.type = "application"
      obj.vendor = "example.com"
      obj.subtype = "user"
      obj.suffix = "json"
      obj.parameters[:version] = "1"
      expect(obj.to_s).to eql('application/vnd.example.com.user+json;version=1')
    end

  end

  describe "comparisons" do
    
    describe "with a string" do
      
      it "should compare matching strings" do
        obj = klass.new("application/json")
        expect(obj == "application/json").to be true
      end

      it "should fail on non-matching strings" do
        obj = klass.new("application/xhtml+xml")
        expect(obj == "application/xml").to be false
      end

      it "should ignore whitespace" do
        obj = klass.new("application/json;version=1")
        expect(obj == "application/json; version=1").to be true
      end

    end

    describe "with an object" do

      it "should compare matching objs" do
        obj = klass.new("application/json")
        obj2 = klass.new("application/json")
        expect(obj == obj2).to be true
      end

      it "should compare non-matching objs" do
        obj = klass.new("application/json")
        obj2 = klass.new("application/xml")
        expect(obj == obj2).to be false
      end

      it "should compare complex objects" do
        obj = klass.new("application/vnd.example.com.user+json;version=1")
        obj2 = klass.new("application/vnd.example.com.user+json;version=1")
        expect(obj == obj2).to be true
      end
     
    end

    describe "with rubbish" do
      it "should raise an exception" do
        obj = klass.new("application/json")
        expect {
          obj == 1
        }.to raise_error(/Invalid type comparison/)
      end
    end
  end

  describe "parameter wrappers" do

    it "should provide charset" do
      obj = klass.new("application/json; charset=UTF-8")
      expect(obj.charset).to eql("UTF-8")
    end

    it "should provide version" do
      obj = klass.new("application/json; version=2")
      expect(obj.version).to eql("2")
    end

  end

  describe "type tests" do

    it "should should match basic json type" do
      obj = klass.new("application/json; version=2")
      expect(obj.json?).to be true
    end

    it "should should match vendored json type" do
      obj = klass.new("application/vnd.example.com.user+json; version=2")
      expect(obj.json?).to be true
    end

    it "should should match basic xml type" do
      obj = klass.new("application/xml")
      expect(obj.json?).to be false
      expect(obj.xml?).to be true
    end

    it "should should match vendored json type" do
      obj = klass.new("application/vnd.example.com.user+xml; version=2")
      expect(obj.json?).to be false
      expect(obj.xml?).to be true
    end

    it "should match text type" do
      obj = klass.new("text/plain")
      expect(obj.text?).to be true
    end

    it "should not match non-text type" do
      obj = klass.new("application/json")
      expect(obj.text?).to be false
    end

    it "should match form type" do
      obj = klass.new("application/x-www-form-urlencoded")
      expect(obj.form?).to be true
    end

    it "should not match non-text type" do
      obj = klass.new("application/json")
      expect(obj.form?).to be false
    end

  end

end
