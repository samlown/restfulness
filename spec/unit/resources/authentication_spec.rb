
require 'spec_helper'

describe Restfulness::Resources::Authentication do

  let :app do
    Class.new(Restfulness::Application) do
      routes do
        # empty
      end
    end
  end
  let :request do
    Restfulness::Request.new(app).tap do |req|
      req.headers[:authorization] = "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="
    end
  end
  let :response do
    Restfulness::Response.new(request)
  end

  describe "#authenticate_with_http_basic" do

    class AuthResource < Restfulness::Resource
    end

    it "should run block and provide user and password" do
      obj = AuthResource.new(request, response)
      expect { |b| obj.authenticate_with_http_basic(&b) }.to yield_control
      obj.authenticate_with_http_basic do |username, password|
        username.should eql('Aladdin')
        password.should eql('open sesame')
      end
    end

    it "should not run block if no authorization header" do
      request.headers[:authorization] = nil
      obj = AuthResource.new(request, response)
      expect { |b| obj.authenticate_with_http_basic(&b) }.not_to yield_control
    end

    it "should not run block if non-basic authorization header" do
      request.headers[:authorization] = "Digest QWxhZGRpbjpvcGVuIHNlc2FtZQ=="
      obj = AuthResource.new(request, response)
      expect { |b| obj.authenticate_with_http_basic(&b) }.not_to yield_control
    end

  end

end
