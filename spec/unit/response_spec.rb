
require 'spec_helper'

describe Restfulness::Response do

  let :klass do
    Restfulness::Response
  end
  let :app do
    Class.new(Restfulness::Application) do
      routes do
        add 'project', Class.new(Restfulness::Resource)
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
      obj.headers.should eql({'Content-Type' => 'application/json'})
      obj.code.should be_nil
    end
  end

  describe "#run" do
    context "without route" do
      it "should not do anything" do
        request.stub(:route).and_return(nil)
        obj.run
        obj.code.should be_nil
        obj.payload.should be_nil
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
        obj.code.should eql(200)
        obj.payload.should eql("{\"foo\":\"bar\"}")
      end      
    end
  end

end
