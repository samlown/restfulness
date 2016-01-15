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
      expect(obj.header).to eql(header)
    end
  end

  describe "#valid?" do
    it "should detect valid schema and credentials" do
      obj = klass.new(header)
      expect(obj.valid?).to be true
    end

    it "should reject different schema" do
      obj = klass.new(header_klass.new("Fooo Bar"))
      expect(obj.valid?).to be false
    end

    it "should reject if the basic request credentials are of invalid length" do
      creds = ::Base64.strict_encode64("username")
      obj = klass.new(header_klass.new("Fooo #{creds}"))
      expect(obj.valid?).to be false
    end
  end

  describe "#credentials #username and #password" do

    it "should decode and prepare the params" do
      obj = klass.new(header)
      expect(obj.credentials.length).to eql(2)
      expect(obj.username).to eql('Aladdin')
      expect(obj.password).to eql('open sesame')
    end

  end

end
