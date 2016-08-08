
require 'spec_helper'

describe Restfulness::Resources::Events do

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

  describe "#error" do

    class Get418Resource < Restfulness::Resource
      def get
        error!(418, {})
      end
    end

    it "should raise a new exception" do
      klass = Get418Resource
      obj = klass.new(request, response)
      expect {
        obj.get
      }.to raise_error(Restfulness::HTTPException, "I'm A Teapot")
    end
  end

  describe "events" do

    let :klass do
      Class.new(Restfulness::Resource)
    end

    let :obj do
      klass.new(request, response)
    end

    describe "generic bang error events" do
      it "should support bad_request!" do
        expect {
          obj.instance_eval do
            bad_request!
          end
        }.to raise_error(Restfulness::HTTPException, "Bad Request")
      end

      it "should support bad_request! with paramters" do
        expect(obj).to receive(:error!).with(400, {:pay => 'load'}, {})
        obj.instance_eval do
          bad_request!({:pay => 'load'}, {})
        end
      end
    end

    describe "success callbacks" do
      
      it "should set status for #ok" do
        obj.instance_eval do
          no_content
        end
        expect(response.status).to eql(204)
      end

      it "should pass through any payload" do
        payload = "foo"
        res = nil
        obj.instance_eval do
          res = created(payload)
        end
        expect(res).to eql(payload)
      end

    end

  end

end
