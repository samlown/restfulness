require 'spec_helper'

describe Restfulness::Requests::AuthorizationHeader do

  describe "#initialize" do

    let :klass do
      Restfulness::Requests::AuthorizationHeader
    end

    it "should accept standard header" do
      obj = klass.new("Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
      obj.schema.should eql("Basic")
      obj.params.should eql("QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
    end

    it "should accept non-standard schema" do
      obj = klass.new("bAsic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
      obj.schema.should eql("Basic")
      obj.params.should eql("QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
    end

    it "should ignore any whitespace" do
      obj = klass.new(" Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ== ")
      obj.schema.should eql("Basic")
      obj.params.should eql("QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
    end

    it "should append additional stuff" do
      obj = klass.new("Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ== foooo")
      obj.schema.should eql("Basic")
      obj.params.should eql("QWxhZGRpbjpvcGVuIHNlc2FtZQ== foooo")
    end

  end

end
