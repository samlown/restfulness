require 'spec_helper'

describe Restfulness::HttpAuthentication::Basic do

  let :klass do
    Restfulness::HttpAuthentication::Basic
  end
  let :header_klass do
    Restfulness::Requests::AuthorizationHeader
  end
  let :header do
    Restfulness::Requests::AuthorizationHeader.new("Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
  end

  describe "#initialize" do
    it "should set the header" do
      obj = klass.new(header)
      obj.header.should eql(header)
    end
  end

  describe "#valid?" do
    it "should detect valid schema and credentials" do
      obj = klass.new(header)
      obj.valid?.should be_true
    end

    it "should reject different schema" do
      obj = klass.new(header_klass.new("Fooo Bar"))
      obj.valid?.should be_false
    end

    it "should reject if the basic request credentials are of invalid length" do
      creds = ::Base64.strict_encode64("username")
      obj = klass.new(header_klass.new("Fooo #{creds}"))
      obj.valid?.should be_false
    end
  end

  describe "#credentials #username and #password" do

    it "should decode and prepare the params" do
      obj = klass.new(header)
      obj.credentials.length.should eql(2)
      obj.username.should eql('Aladdin')
      obj.password.should eql('open sesame')
    end

  end

end
