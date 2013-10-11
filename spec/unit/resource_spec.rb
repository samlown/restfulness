require 'spec_helper'

describe Restfulness::Resource do

  let :app do
    Class.new(Restfulness::Application) do
      routes do
        # empty
      end
    end
  end
  let :request do
    Restfulness::Request.new(app)
  end
  let :response do
    Restfulness::Response.new(request)
  end

  describe "#initialize" do
    let :resource do
      Class.new(Restfulness::Resource) do
        def get
          'result'
        end
      end
    end
    it "should assign request and response" do
      obj = resource.new(request, response)
      obj.request.should eql(request)
      obj.response.should eql(response)
    end
  end

  describe "#options" do
    let :resource do
      Class.new(Restfulness::Resource) do
        def get
          'result'
        end
        def post
          'post'
        end
      end
    end

    it "should return list of supported methods" do
      obj = resource.new(request, response)
      obj.options.should be_nil
      response.headers['Allow'].should eql('GET, POST')
    end
  end

  describe "#call" do
    let :resource do
      Class.new(Restfulness::Resource) do
        def get
          'result'
        end
      end
    end
    it "should perform action" do
      request.action = :get
      obj = resource.new(request, response)
      obj.should_receive(:get).and_return('res')
      obj.call.should eql('res')
    end

  end

  describe "#method_allowed?" do
    let :resource do
      Class.new(Restfulness::Resource) do
        def get
          'result'
        end
        def post
          'post'
        end
      end
    end

    it "should be true on valid method" do
      request.action = :get
      obj = resource.new(request, response)
      obj.method_allowed?.should be_true
    end

    it "should be false on invalid method" do
      request.action = :put
      obj = resource.new(request, response)
      obj.method_allowed?.should be_false
    end
  end

  describe "basic callback responses" do
    let :resource do
      Class.new(Restfulness::Resource) do
        def get
          'result'
        end
        def post
          'post'
        end
      end
    end

    let :obj do
      request.action = :get
      obj = resource.new(request, response)
    end

    it "should all be true for questions" do
      obj.exists?.should be_true
      obj.authorized?.should be_true
      obj.allowed?.should be_true
    end

    it "should be nil for values" do
      obj.last_modified.should be_nil
      obj.etag.should be_nil
    end
  end

  describe "#check_callbacks" do

  end

end
