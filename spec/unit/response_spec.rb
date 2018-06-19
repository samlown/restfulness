
require 'spec_helper'

describe Restfulness::Response do

  class ResponseResource < Restfulness::Resource
    def get
      ""
    end
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
      expect(obj.request).to eql(request)
      expect(obj.headers).to eql({})
      expect(obj.status).to be_nil
      expect(obj.payload).to be_nil
    end
  end

  describe "#status=" do
    it "should allow status to be forced" do
      obj.status = 204
      expect(obj.status).to eql(204)
    end
    it "should convert non-integer status to integer" do
      obj.status = "203"
      expect(obj.status).to eql(203)
    end
    it "should not overwrite on execution" do
      route = app.router.routes.first
      allow(request).to receive(:route).and_return(route)
      allow(request).to receive(:uri).and_return(URI('http://test.com/test'))
      obj.status = 205
      obj.run
      expect(obj.status).to eql(205)
    end
  end

  describe "#run" do
    context "without route" do
      it "should not do anything" do
        allow(request).to receive(:route).and_return(nil)
        allow(request).to receive(:uri).and_return(URI('http://test.com/test'))
        obj.run
        expect(obj.status).to eql(404)
        expect(obj.payload).to be_empty
        expect(obj.headers['Content-Type']).to be_nil
        expect(obj.headers['Content-Length']).to be_nil
      end
    end
    context "with route" do
      let :route do
        app.router.routes.first
      end

      it "should try to build resource and run it" do
        allow(request).to receive(:route).and_return(route)
        request.action = :get
        allow(request).to receive(:uri).and_return(URI('http://test.com/test'))
        resource = double(:Resource)
        expect(resource).to receive(:check_callbacks)
        expect(resource).to receive(:call).and_return({:foo => 'bar'})
        allow(route).to receive(:build_resource).and_return(resource)
        obj.run
        expect(obj.status).to eql(200)
        str = "{\"foo\":\"bar\"}"
        expect(obj.payload).to eql(str)
        expect(obj.headers['Content-Type']).to match(/application\/json/)
        expect(obj.headers['Content-Length']).to eql(str.bytesize.to_s)
      end

      it "should call resource and set 204 result if no content" do
        allow(request).to receive(:route).and_return(route)
        request.action = :get
        allow(request).to receive(:uri).and_return(URI('http://test.com/test'))
        resource = double(:Resource)
        expect(resource).to receive(:check_callbacks)
        expect(resource).to receive(:call).and_return(nil)
        allow(route).to receive(:build_resource).and_return(resource)
        obj.run
        expect(obj.status).to eql(204)
        expect(obj.headers['Content-Type']).to be_nil
        expect(obj.headers['Content-Length']).to be_nil
      end

      it "should set string content type if payload is a string" do
        allow(request).to receive(:route).and_return(route)
        request.action = :get
        allow(request).to receive(:uri).and_return(URI('http://test.com/test'))
        resource = double(:Resource)
        expect(resource).to receive(:check_callbacks)
        expect(resource).to receive(:call).and_return("This is a text message")
        allow(route).to receive(:build_resource).and_return(resource)
        obj.run
        expect(obj.status).to eql(200)
        expect(obj.headers['Content-Type']).to match(/text\/plain/)
      end
    end

    context "with exceptions" do
      let :route do
        app.router.routes.first
      end

      it "should update the status and payload" do
        allow(request).to receive(:route).and_return(route)
        request.action = :get
        allow(request).to receive(:uri).and_return(URI('http://test.com/test'))
        resource = double(:Resource, rescue_with_handler: nil)
        txt = "This is a text error"
        allow(resource).to receive(:check_callbacks) do
          raise Restfulness::HTTPException.new(418, txt)
        end
        allow(route).to receive(:build_resource).and_return(resource)
        obj.run
        expect(obj.status).to eql(418)
        expect(obj.headers['Content-Type']).to match(/text\/plain/)
        expect(obj.payload).to eql(txt)
      end

      it "should update the status and provide JSON payload" do
        allow(request).to receive(:route).and_return(route)
        request.action = :get
        allow(request).to receive(:uri).and_return(URI('http://test.com/test'))
        resource = double(:Resource, rescue_with_handler: nil)
        err = {:error => "This is a text error"}
        allow(resource).to receive(:check_callbacks) do
          raise Restfulness::HTTPException.new(418, err)
        end
        allow(route).to receive(:build_resource).and_return(resource)
        obj.run
        expect(obj.status).to eql(418)
        expect(obj.headers['Content-Type']).to match(/application\/json/)
        expect(obj.payload).to eql(err.to_json)
      end

      context "for non http errors" do

        it "should catch error and provide result" do
          allow(request).to receive(:route).and_return(route)
          request.action = :get
          allow(request).to receive(:uri).and_return(URI('http://test.com/test'))
          resource = double(:Resource, rescue_with_handler: nil)
          allow(resource).to receive(:check_callbacks) do
            raise SyntaxError, 'Bad writing'
          end
          allow(route).to receive(:build_resource).and_return(resource)
          obj.run
          expect(obj.status).to eql(500)
          expect(obj.payload).to eql("Bad writing\n")
        end

      end

      context "when use rescue_from at resource level" do
        before do
          ResponseResource.rescue_from RuntimeError do |exception|
            error!(500, { message: 'Internal Server Error' }, {headers: {'X-id' => 'foo'}})
          end
          request.uri = "/project"
          request.action = :get
        end

        it "should populate status and payload as demanded" do
          allow_any_instance_of(ResponseResource).to receive(:send).with(:get).and_raise(RuntimeError, "foo")

          obj.run

          expect(obj.status).to eq(500)
          expect(obj.payload).to eq("{\"message\":\"Internal Server Error\"}")
          expect(obj.headers).to eq({"X-id" => "foo", "Content-Type" => "application/json; charset=utf-8", "Content-Length" => "35"})
        end

        it "should be handle by the response if not handled by the resource" do
          allow_any_instance_of(ResponseResource).to receive(:send).with(:get).and_raise(StandardError, "foo")

          obj.run

          expect(obj.status).to eq(500)
          expect(obj.payload).to eq("foo\n")
          expect(obj.headers).to eq({"Content-Type" => "text/plain; charset=utf-8", "Content-Length" => "4"})
        end
      end

    end

  end

  describe "content type handling" do
    before :each do
      request.uri = "http://localhost:3000/project"
      request.action = :get
    end
    context "nil content" do
      it "should not set content headers" do
        allow_any_instance_of(ResponseResource).to receive(:get).and_return(nil)
        obj.run
        expect(obj.headers['Content-Type']).to be_nil
      end
    end
    context "empty content" do
      it "should not set content headers" do
        allow_any_instance_of(ResponseResource).to receive(:get).and_return("")
        obj.run
        expect(obj.headers['Content-Type']).to be_nil
      end
    end
    context "json requested with content" do
      let :accept do
        Restfulness::Headers::Accept.new("application/json")
      end
      it "should set json content headers" do
        allow(request).to receive(:accept).and_return(accept)
        allow_any_instance_of(ResponseResource).to receive(:get).and_return({foo: "bar"})
        obj.run
        expect(obj.headers['Content-Type']).to match(/application\/json/)
      end
    end
    context "xml requested with content" do
      let :accept do
        Restfulness::Headers::Accept.new("application/xml")
      end
      it "should set xml content headers" do
        allow(request).to receive(:accept).and_return(accept)
        allow_any_instance_of(ResponseResource).to receive(:get).and_return({foo: "bar"})
        obj.run
        expect(obj.headers['Content-Type']).to match(/application\/xml/)
        expect(obj.payload).to match("<?xml version=\"1.0\"")
      end
      it "should set xml content headers even if string provided by resource" do
        allow(request).to receive(:accept).and_return(accept)
        allow_any_instance_of(ResponseResource).to receive(:get).and_return({foo: "bar"}.to_xml.to_s)
        obj.run
        expect(obj.headers['Content-Type']).to match(/application\/xml/)
        expect(obj.payload).to match("<?xml version=\"1.0\"")
      end
    end
    context "string requested with content" do
      let :accept do
        Restfulness::Headers::Accept.new("text/plain")
      end
      it "should set xml content headers" do
        allow(request).to receive(:accept).and_return(accept)
        allow_any_instance_of(ResponseResource).to receive(:get).and_return({foo: "bar"}.to_s)
        obj.run
        expect(obj.headers['Content-Type']).to match("text/plain")
      end
    end
    context "default with content" do
      it "should set json content headers" do
        allow_any_instance_of(ResponseResource).to receive(:get).and_return({foo: "bar"})
        obj.run
        expect(obj.headers['Content-Type']).to match(/application\/json/)
      end
    end
    context "overriding" do
      it "should allow the content type to be overriden" do
        obj.headers['Content-Type'] = 'application/foo'
        allow_any_instance_of(ResponseResource).to receive(:get).and_return({foo: "bar"})
        obj.run
        expect(obj.headers['Content-Type']).to match("application/foo")
      end
    end
  end

end
