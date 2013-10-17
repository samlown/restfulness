
require 'spec_helper'

describe Restfulness::Response do

  class ResponseResource < Restfulness::Resource
  end

  let :klass do
    Restfulness::Response
  end
  let :app do
    Class.new(Restfulness::Application) do
      routes do
        add 'project', ResponseResource
      end
    end
  end
  let :request do
    Restfulness::Request.new(app)
  end
  let :obj do
    klass.new(request)
  end

  describe "#initialize" do
    it "should assign request and headers" do
      obj.request.should eql(request)
      obj.headers.should eql({})
      obj.status.should be_nil
      obj.payload.should be_nil
    end
  end

  describe "#run" do
    context "without route" do
      it "should not do anything" do
        request.stub(:route).and_return(nil)
        obj.run
        obj.status.should eql(404)
        obj.payload.should be_empty
        obj.headers['Content-Type'].should match(/text\/plain/)
        obj.headers['Content-Length'].should eql(0.to_s)
      end
    end
    context "with route" do
      let :route do
        app.router.routes.first
      end

      it "should try to build resource and run it" do
        request.stub(:route).and_return(route)
        request.action = :get
        resource = double(:Resource)
        resource.should_receive(:check_callbacks)
        resource.should_receive(:call).and_return({:foo => 'bar'})
        route.stub(:build_resource).and_return(resource)
        obj.run 
        obj.status.should eql(200)
        str = "{\"foo\":\"bar\"}"
        obj.payload.should eql(str)
        obj.headers['Content-Type'].should match(/application\/json/)
        obj.headers['Content-Length'].should eql(str.bytesize.to_s)
      end

      it "should call resource and set 204 result if no content" do
        request.stub(:route).and_return(route)
        request.action = :get
        resource = double(:Resource)
        resource.should_receive(:check_callbacks)
        resource.should_receive(:call).and_return(nil)
        route.stub(:build_resource).and_return(resource)
        obj.run
        obj.status.should eql(204)
        obj.headers['Content-Type'].should match(/text\/plain/)
      end

      it "should set string content type if payload is a string" do
        request.stub(:route).and_return(route)
        request.action = :get
        resource = double(:Resource)
        resource.should_receive(:check_callbacks)
        resource.should_receive(:call).and_return("This is a text message")
        route.stub(:build_resource).and_return(resource)
        obj.run
        obj.status.should eql(200)
        obj.headers['Content-Type'].should match(/text\/plain/)
      end
    end

    context "with exceptions" do
      let :route do
        app.router.routes.first
      end

      it "should update the status and payload" do
        request.stub(:route).and_return(route)
        request.action = :get
        resource = double(:Resource)
        txt = "This is a text error"
        resource.stub(:check_callbacks) do
          raise Restfulness::HTTPException.new(418, txt)
        end
        route.stub(:build_resource).and_return(resource)
        obj.run
        obj.status.should eql(418)
        obj.headers['Content-Type'].should match(/text\/plain/)
        obj.payload.should eql(txt)
      end

      it "should update the status and provide JSON payload" do
        request.stub(:route).and_return(route)
        request.action = :get
        resource = double(:Resource)
        err = {:error => "This is a text error"}
        resource.stub(:check_callbacks) do
          raise Restfulness::HTTPException.new(418, err)
        end
        route.stub(:build_resource).and_return(resource)
        obj.run
        obj.status.should eql(418)
        obj.headers['Content-Type'].should match(/application\/json/)
        obj.payload.should eql(err.to_json)
      end


    end

  end

end
