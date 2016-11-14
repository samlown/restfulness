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

  # Fake IO class, meant to mimic Puma::NullIO
  class EmptyIO
    def read(count = nil, buffer = nil); ""; end
  end


  describe "#initialize" do
    it "should prepare basic objects" do
      expect(obj.action).to be_nil
      expect(obj.headers).to eql({})
      expect(obj.body).to be_nil
    end
  end

  describe "#uri=" do
    it "should convert URL into URI" do
      obj.uri = "https://example.com/project/12345"
      expect(obj.uri.path).to eql("/project/12345")
    end
  end

  describe "#action" do
    it "should provide basic action" do
      obj.action = :get
      expect(obj.action).to eql(:get)
    end
  end

  describe "#path" do
    it "should be nil if there is no route" do
      allow(obj).to receive(:route).and_return(nil)
      expect(obj.path).to be_nil
    end

    context "with route" do
      let :path do
        obj.uri = "https://example.com/project/12345"
        route = Restfulness::Route.new('project', resource)
        allow(obj).to receive(:route).and_return(route)
        obj.path
      end

      it "should build path" do
        expect(path.to_s).to eql('/project/12345')
      end

      it "should re-use same path object" do
        expect(path.object_id).to eql(obj.path.object_id)
      end
    end
  end

  describe "#route" do
    it "should ask the router for a route" do
      obj.uri = "https://example.com/project/12345"
      route = double(:Route)
      expect(app.router).to receive(:route_for).with(obj.uri.path).and_return(route)
      expect(obj.route).to eql(route)
    end
  end

  describe "#query" do
    it "should parse uri with query" do
      obj.uri = "https://example.com/project/12345?foo=bar&test=23"
      expect(obj.query).to be_a(HashWithIndifferentAccess)
      expect(obj.query[:foo]).to eql('bar')
      expect(obj.query[:test].to_i).to eql(23)
    end

    it "should handle uri with empty query" do
      obj.uri = "https://example.com/project/12345"
      expect(obj.query).to be_empty
    end

    it "should handle complex query items" do
      obj.uri = "https://example.com/project/12345?foo[]=bar&foo[]=bar2&hash[a]=b&hash[b]=c"
      expect(obj.query[:foo]).to eql(['bar', 'bar2'])
      expect(obj.query[:hash]).to be_a(HashWithIndifferentAccess)
      expect(obj.query[:hash][:a]).to eql('b')
    end
  end

  describe "#sanitized_query_string" do
    it "should be empty if no query" do
      obj.uri = "https://example.com/project/12345"
      expect(obj.sanitized_query_string).to be_empty
    end
    it "should filter out bad keys" do # See sanitizer tests for more
      obj.uri = "https://example.com/project/12345?foo=bar&password=safe"
      expect(obj.sanitized_query_string).to match(/foo=bar/)
      expect(obj.sanitized_query_string).not_to match(/password=safe/)
    end
  end

  describe "#content_type" do
    it "should be nil if no content type" do
      expect(obj.content_type).to be_nil
    end

    it "should provide a content type object for the request" do
      obj.headers[:content_type] = "application/json; charset=utf-8"
      expect(obj.content_type).to be_a(Restfulness::Headers::MediaType)
      expect(obj.content_type.json?).to be true
    end

    it "should cache content_type object" do
      obj.headers[:content_type] = "application/json"
      obj.content_type.freeze
      expect(obj.content_type.frozen?).to be true
    end
  end

  describe "#accept" do
    it "should be nil if no accept header provided" do
      expect(obj.accept).to be_nil
    end
    it "should provide a accept object for the request" do
      obj.headers[:accept] = "application/json; version=3"
      expect(obj.accept).to be_a(Restfulness::Headers::Accept)
      expect(obj.accept.json?).to be true
      expect(obj.accept.version).to eql("3")
    end
  end

  describe "#params" do
    it "should not return anything for empty body" do
      allow(obj).to receive(:body).and_return(nil)
      expect(obj.params).to be_empty
    end

    it "should raise 400 bad request for invalid json body" do
      obj.headers[:content_type] = "application/json; charset=utf-8"
      allow(obj).to receive(:body).and_return('{"data":"invalid}')
      expect {
        obj.params
      }.to raise_error(Restfulness::HTTPException, "Bad Request"){ |exception|
        expect(exception.status).to eq 400
        expect(exception.payload).to eq "Invalid JSON in request body"
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
      expect(obj.params['foo']).to eql('bar')
    end

    it "should decode a WWW Form body" do
      obj.headers[:content_type] = "application/x-www-form-urlencoded"
      obj.body = "grant_type=password&username=johndoe&password=A3ddj3w"
      expect(obj.params['grant_type']).to eql('password')
      expect(obj.params['username']).to eql('johndoe')
    end

    it "should deal with empty WWW Form body" do
      obj.headers[:content_type] = "application/x-www-form-urlencoded"
      obj.body = ""
      expect(obj.params).to be_empty
    end

    it "should deal with a StringIO WWW form body" do
      obj.headers[:content_type] = "application/x-www-form-urlencoded"
      obj.body = StringIO.new("grant_type=password&username=johndoe&password=A3ddj3w")
      expect(obj.params['grant_type']).to eql('password')
      expect(obj.params['username']).to eql('johndoe')
    end

    it "should deal with a Tempfile WWW form body" do
      obj.headers[:content_type] = "application/x-www-form-urlencoded"
      file = Tempfile.new("params")
      file.write("grant_type=password&username=johndoe&password=A3ddj3w")
      file.rewind
      obj.body = file
      expect(obj.params['grant_type']).to eql('password')
      expect(obj.params['username']).to eql('johndoe')
    end

    it "should deal with empty JSON String body" do
      obj.headers[:content_type] = "application/json"
      obj.body = ""
      expect(obj.params).to be_empty
    end

    it "should deal with empty JSON StringIO body" do
      obj.headers[:content_type] = "application/json"
      obj.body = StringIO.new("")
      expect(obj.params).to be_empty
    end

    it "should handle some crappy IO object" do
      obj.body = EmptyIO.new()
      expect(obj.body).to receive(:read)
      expect(obj.params).to be_empty
    end

    it "should rewind IO body object when reading it" do
      obj.headers[:content_type] = "application/x-www-form-urlencoded"
      obj.body = StringIO.new("grant_type=password&username=johndoe&password=A3ddj3w")

      expect(obj.params.keys).to eql(['grant_type', 'username', 'password'])
      expect(obj.body.read).to eql('grant_type=password&username=johndoe&password=A3ddj3w')
    end
  end

  describe "#sanitized_params" do
    it "should provide nil if the params hash has not been used" do
      allow(obj).to receive(:body).and_return(nil)
      expect(obj.sanitized_params).to be_nil
    end
    it "should provide santized params if params have been used" do
      obj.headers[:content_type] = "application/json"
      obj.body = "{\"foo\":\"bar\",\"password\":\"safe\"}"
      expect(obj.params['password']).to eql('safe')
      expect(obj.sanitized_params['foo']).to eql('bar')
      expect(obj.sanitized_params['password']).not_to be_blank
      expect(obj.sanitized_params['password']).not_to eql('safe')
    end
  end

  describe "#http_accept_language" do
    it "should provide an instance of Parser" do
      expect(obj.http_accept_language).to be_a(HttpAcceptLanguage::Parser)
    end
    it "should use the accept_language header" do
      header = "en-us,en-gb;q=0.8,en"
      obj.headers[:accept_language] = header
      expect(obj.http_accept_language.header).to eql(header)
    end
  end

  describe "method helpers" do
    it "should respond to method questions" do
      [:get?, :post?, :put?, :delete?, :head?, :options?].each do |q|
        expect(obj).to respond_to(q)
      end
    end
    it "should suggest type of method" do
      obj.action = :get
      expect(obj.get?).to be true
      expect(obj.post?).to be false
    end
  end

end
