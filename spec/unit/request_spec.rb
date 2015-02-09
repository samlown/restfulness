require 'spec_helper'

describe Restfulness::Request do

  let :app do
    Class.new(Restfulness::Application) do
      routes do
        # nothing
      end
    end
  end
  
  let :klass do
    Restfulness::Request
  end

  let :obj do
    klass.new(app)
  end

  class RequestResource < Restfulness::Resource
  end
  let :resource do
    RequestResource
  end
    
  
  describe "#initialize" do
    it "should prepare basic objects" do
      obj.action.should be_nil
      obj.headers.should eql({})
      obj.body.should be_nil
    end
  end

  describe "#uri=" do
    it "should convert URL into URI" do
      obj.uri = "https://example.com/project/12345"
      obj.uri.path.should eql("/project/12345")
    end
  end

  describe "#action" do
    it "should provide basic action" do
      obj.action = :get
      obj.action.should eql(:get)
    end
  end

  describe "#path" do
    it "should be nil if there is no route" do
      obj.stub(:route).and_return(nil)
      obj.path.should be_nil
    end

    context "with route" do
      let :path do
        obj.uri = "https://example.com/project/12345"
        route = Restfulness::Route.new('project', resource)
        obj.stub(:route).and_return(route)
        obj.path
      end

      it "should build path" do
        path.to_s.should eql('/project/12345')
      end

      it "should re-use same path object" do
        path.object_id.should eql(obj.path.object_id)
      end
    end
  end

  describe "#route" do
    it "should ask the router for a route" do
      obj.uri = "https://example.com/project/12345"
      route = double(:Route)
      app.router.should_receive(:route_for).with(obj.uri.path).and_return(route)
      obj.route.should eql(route)
    end
  end

  describe "#query" do
    it "should parse uri with query" do
      obj.uri = "https://example.com/project/12345?foo=bar&test=23"
      obj.query.should be_a(HashWithIndifferentAccess)
      obj.query[:foo].should eql('bar')
      obj.query[:test].to_i.should eql(23)
    end

    it "should handle uri with empty query" do
      obj.uri = "https://example.com/project/12345"
      obj.query.should be_empty
    end

    it "should handle complex query items" do
      obj.uri = "https://example.com/project/12345?foo[]=bar&foo[]=bar2&hash[a]=b&hash[b]=c"
      obj.query[:foo].should eql(['bar', 'bar2'])
      obj.query[:hash].should be_a(HashWithIndifferentAccess)
      obj.query[:hash][:a].should eql('b')
    end
  end

  describe "#sanitized_query_string" do
    it "should be empty if no query" do
      obj.uri = "https://example.com/project/12345"
      obj.sanitized_query_string.should be_empty
    end
    it "should filter out bad keys" do # See sanitizer tests for more
      obj.uri = "https://example.com/project/12345?foo=bar&password=safe"
      obj.sanitized_query_string.should match(/foo=bar/)
      obj.sanitized_query_string.should_not match(/password=safe/)
    end
  end

  describe "#params" do
    it "should not return anything for empty body" do
      obj.stub(:body).and_return(nil)
      obj.params.should be_empty
    end

    it "should raise 400 bad request for invalid json body" do
      obj.headers[:content_type] = "application/json; charset=utf-8"
      obj.stub(:body).and_return("invalidjson!")
      expect {
        obj.params
      }.to raise_error(Restfulness::HTTPException, "Bad Request"){ |exception|
        expect(exception.status).to eq 400
      }
    end

    it "should raise 406 error if no content type" do
      obj.headers[:content_type] = nil
      obj.body = "{\"foo\":\"bar\"}"
      expect {
        obj.params
      }.to raise_error(Restfulness::HTTPException, "Not Acceptable"){ |exception|
        expect(exception.status).to eq 406
      }
    end

    it "should decode a JSON body with utf-8 encoding" do
      obj.headers[:content_type] = "application/json; charset=utf-8"
      obj.body = "{\"foo\":\"bar\"}"
      expect {
        obj.params
      }.not_to raise_error
    end

    it "should decode a JSON body" do
      obj.headers[:content_type] = "application/json"
      obj.body = "{\"foo\":\"bar\"}"
      obj.params['foo'].should eql('bar')
    end

    it "should decode a WWW Form body" do
      obj.headers[:content_type] = "application/x-www-form-urlencoded"
      obj.body = "grant_type=password&username=johndoe&password=A3ddj3w"
      obj.params['grant_type'].should eql('password')
      obj.params['username'].should eql('johndoe')
    end

    it "should deal with empty WWW Form body" do
      obj.headers[:content_type] = "application/x-www-form-urlencoded"
      obj.body = ""
      obj.params.should be_empty
    end

    it "should deal with a StringIO WWW form body" do
      obj.headers[:content_type] = "application/x-www-form-urlencoded"
      obj.body = StringIO.new("grant_type=password&username=johndoe&password=A3ddj3w")
      obj.params['grant_type'].should eql('password')
      obj.params['username'].should eql('johndoe')
    end

    it "should deal with empty JSON String body" do
      obj.headers[:content_type] = "application/json"
      obj.body = ""
      obj.params.should be_empty
    end

    it "should deal with empty JSON StringIO body" do
      obj.headers[:content_type] = "application/json"
      obj.body = StringIO.new("")
      obj.params.should be_empty
    end
  end

  describe "#sanitized_params" do
    it "should provide nil if the params hash has not been used" do
      obj.stub(:body).and_return(nil)
      obj.sanitized_params.should be_nil
    end
    it "should provide santized params if params have been used" do
      obj.headers[:content_type] = "application/json"
      obj.body = "{\"foo\":\"bar\",\"password\":\"safe\"}"
      obj.params['password'].should eql('safe')
      obj.sanitized_params['foo'].should eql('bar')
      obj.sanitized_params['password'].should_not be_blank
      obj.sanitized_params['password'].should_not eql('safe')
    end
  end

  describe "#http_accept_language" do
    it "should provide an instance of Parser" do
      obj.http_accept_language.should be_a(HttpAcceptLanguage::Parser)
    end
    it "should use the accept_language header" do
      header = "en-us,en-gb;q=0.8,en"
      obj.headers[:accept_language] = header
      obj.http_accept_language.header.should eql(header)
    end
  end

  describe "method helpers" do
    it "should respond to method questions" do
      [:get?, :post?, :put?, :delete?, :head?, :options?].each do |q|
        obj.should respond_to(q)
      end
    end
    it "should suggest type of method" do
      obj.action = :get
      obj.get?.should be_true
      obj.post?.should be_false
    end
  end

end
