
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

  describe "generic bang error events" do

    let :klass do
      Class.new(Restfulness::Resource)
    end

    let :obj do
      klass.new(request, response)
    end

    it "should support bad_request!" do
      expect {
        obj.instance_eval do
          bad_request!
        end
      }.to raise_error(Restfulness::HTTPException, "Bad Request")
    end

    it "should support bad_request! with paramters" do
      obj.should_receive(:error!).with(400, {:pay => 'load'}, {})
      obj.instance_eval do
        bad_request!({:pay => 'load'}, {})
      end
    end


  end

  

end
