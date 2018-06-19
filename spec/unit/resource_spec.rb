require 'spec_helper'

describe Restfulness::Resource do

  class GetResource < Restfulness::Resource
    def get
      'result'
    end
  end

  class GetPostResource < Restfulness::Resource
    def get
      'result'
    end
    def post
      'post'
    end
  end

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
      GetResource
    end
    it "should assign request and response" do
      obj = resource.new(request, response)
      expect(obj.request).to eql(request)
      expect(obj.response).to eql(response)
    end
  end

  describe "#options" do
    let :resource do
      GetPostResource
    end

    it "should return list of supported methods" do
      obj = resource.new(request, response)
      expect(obj.options).to be_nil
      acts = response.headers['Allow'].split(/, /)
      ['GET', 'POST', 'OPTIONS'].each do |act|
        expect(acts).to include(act)
      end
    end
  end

  describe "#call" do
    let :resource do
      GetResource
    end
    it "should perform action" do
      request.action = :get
      obj = resource.new(request, response)
      expect(obj).to receive(:get).and_return('res')
      expect(obj.call).to eql('res')
    end

  end

  describe "#method_allowed?" do
    let :resource do
      GetPostResource
    end

    it "should be true on valid method" do
      request.action = :get
      obj = resource.new(request, response)
      expect(obj.method_allowed?).to be true
    end

    it "should be false on invalid method" do
      request.action = :put
      obj = resource.new(request, response)
      expect(obj.method_allowed?).to be false
    end
  end

  describe "basic callback responses" do
    let :resource do
      GetPostResource
    end

    let :obj do
      request.action = :get
      obj = resource.new(request, response)
    end

    it "should all be true for questions" do
      expect(obj.exists?).to be true
      expect(obj.authorized?).to be true
      expect(obj.allowed?).to be true
    end

    it "should be nil for values" do
      expect(obj.last_modified).to be_nil
      expect(obj.etag).to be_nil
    end
  end

  describe "#check_callbacks" do
    let :resource do
      Class.new(GetPostResource) do
        def head; nil; end
        def put; nil; end
        def delete; nil; end
      end
    end

    let :obj do
      request.action = :get
      resource.new(request, response)
    end

    it "should all be good by default" do
      expect {
        obj.check_callbacks
      }.to_not raise_error
    end

    it "should try to set the locale" do
      expect(obj).to receive(:set_locale)
      obj.check_callbacks
    end

    it "should raise error on invalid method" do
      allow(obj).to receive(:method_allowed?).and_return(false)
      expect {
        obj.check_callbacks
      }.to raise_error(Restfulness::HTTPException, "Method Not Allowed")
    end

    [:head, :get, :patch, :delete].each do |action|
      it "should raise error when not exists for #{action.to_s.upcase}" do
        request.action = action
        allow(obj).to receive(:exists?).and_return(false)
        expect {
          obj.check_callbacks
        }.to raise_error(Restfulness::HTTPException, "Resource Not Found")
      end
    end

    [:put, :post].each do |action|
      it "should not check exists? for #{action.to_s.upcase}" do
        obj.request.action = action
        expect(obj).not_to receive(:exists?)
        obj.check_callbacks
      end
    end

    it "should raise error when not authorized" do
      allow(obj).to receive(:authorized?).and_return(false)
      expect {
        obj.check_callbacks
      }.to raise_error(Restfulness::HTTPException, "Unauthorized")
    end

    it "should raise error when not allowed" do
      allow(obj).to receive(:allowed?).and_return(false)
      expect {
        obj.check_callbacks
      }.to raise_error(Restfulness::HTTPException, "Forbidden")
    end

    describe "with etag" do
      it "should raise error when equal" do
        allow(obj).to receive(:etag).and_return('sometag')
        request.headers[:if_none_match] = 'sometag'
        expect {
          obj.check_callbacks
        }.to raise_error(Restfulness::HTTPException, "Not Modified")
      end

      it "should continue if not equal" do
        allow(obj).to receive(:etag).and_return('sometag')
        request.headers[:if_none_match] = 'someoldtag'
        expect {
          obj.check_callbacks
        }.to_not raise_error
      end

      it "should not be called unless action is :get or :head" do
        expect(obj).not_to receive(:etag)
        request.headers[:if_none_match] = 'sometag'
        [:post, :put, :delete].each do |action|
          request.action = action
          obj.check_callbacks
        end
      end
    end

    describe "with if modified" do
      it "should raise error when equal" do
        time = Time.now
        allow(obj).to receive(:last_modified).and_return(time)
        request.headers[:if_modified_since] = time.to_s
        expect {
          obj.check_callbacks
        }.to raise_error(Restfulness::HTTPException, "Not Modified")
      end

      it "should continue if not equal" do
        time = Time.now
        allow(obj).to receive(:last_modified).and_return(time)
        request.headers[:if_modified_since] = (time - 60).to_s
        expect {
          obj.check_callbacks
        }.to_not raise_error
      end

      it "should not be called unless action is :get or :head" do
        expect(obj).not_to receive(:last_modified)
        request.headers[:if_modified_since] = 'somedate'
        [:post, :put, :delete].each do |action|
          request.action = action
          obj.check_callbacks
        end
      end

    end
  end

  describe "Locale handling" do

    let :resource do
      Class.new(GetPostResource) do
        def head; nil; end
        def put; nil; end
        def delete; nil; end
      end
    end

    let :obj do
      request.headers[:accept_language] = "nl, es, en"
      request.action = :get
      resource.new(request, response)
    end

    describe "#locale" do
      it "should return acceptable locale" do
        I18n.available_locales = ['es']
        expect(obj.send(:locale)).to eql(:es)
      end
    end

    describe "#set_locale" do
      it "should set the global locale value" do
        I18n.available_locales = ['en', 'es']
        expect(I18n.locale).not_to eql(:es)
        obj.send(:set_locale)
        expect(I18n.locale).to eql(:es)
      end
    end

  end

end
