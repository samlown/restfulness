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

    it "should all be good by default" do
      expect {
        obj.check_callbacks
      }.to_not raise_error
    end

    it "should raise error on invalid method" do
      obj.stub(:method_allowed?).and_return(false)
      expect {
        obj.check_callbacks
      }.to raise_error(Restfulness::HTTPException, "Method Not Allowed")
    end

    it "should raise error when not exists" do
      obj.stub(:exists?).and_return(false)
      expect {
        obj.check_callbacks
      }.to raise_error(Restfulness::HTTPException, "Resource Not Found")
    end

    it "should raise error when not authorized" do
      obj.stub(:authorized?).and_return(false)
      expect {
        obj.check_callbacks
      }.to raise_error(Restfulness::HTTPException, "Unauthorized")
    end

    it "should raise error when not allowed" do
      obj.stub(:allowed?).and_return(false)
      expect {
        obj.check_callbacks
      }.to raise_error(Restfulness::HTTPException, "Forbidden")
    end

    describe "with etag" do
      it "should raise error when equal" do
        obj.stub(:etag).and_return('sometag')
        request.headers[:if_none_match] = 'sometag'
        expect {
          obj.check_callbacks
        }.to raise_error(Restfulness::HTTPException, "Not Modified")
      end

      it "should continue if not equal" do
        obj.stub(:etag).and_return('sometag')
        request.headers[:if_none_match] = 'someoldtag'
        expect {
          obj.check_callbacks
        }.to_not raise_error
      end
    end

    describe "with if modified" do
      it "should raise error when equal" do
        time = Time.now
        obj.stub(:last_modified).and_return(time)
        request.headers[:if_modified_since] = time.to_s
        expect {
          obj.check_callbacks
        }.to raise_error(Restfulness::HTTPException, "Not Modified")
      end

      it "should continue if not equal" do
        time = Time.now
        obj.stub(:last_modified).and_return(time)
        request.headers[:if_modified_since] = (time - 60).to_s
        expect {
          obj.check_callbacks
        }.to_not raise_error
      end
    end
  end

  describe "#error" do

    it "should raise a new exception" do
      klass = Class.new(Restfulness::Resource) do
        def get
          error(418, {})
        end
      end
      obj = klass.new(request, response)
      expect {
        obj.get
      }.to raise_error(Restfulness::HTTPException, "I'm A Teapot")
    end

  end

end
