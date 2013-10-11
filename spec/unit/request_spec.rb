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

  describe "#path" do
    it "should be nil if there is no route" do
      obj.stub(:route).and_return(nil)
      obj.path.should be_nil
    end

    context "with route" do
      let :path do
        obj.uri = "https://example.com/project/12345"
        route = Restfulness::Route.new('project', Class.new(Restfulness::Resource))
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
      app.router.should_receive(:route_for).with(obj.uri).and_return(route)
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

  describe "#params" do
    it "should not return anything for empty body" do
      obj.stub(:body).and_return(nil)
      obj.params.should be_nil
    end
    it "should raise 406 error if no content type" do
      obj.headers[:content_type] = nil
      obj.body = "{\"foo\":\"bar\"}"
      expect {
        obj.params
      }.to raise_error(Restfulness::HTTPException, "Not Acceptable")
    end
    it "should decode a JSON body" do
      obj.headers[:content_type] = "application/json"
      obj.body = "{\"foo\":\"bar\"}"
      obj.params['foo'].should eql('bar')
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
