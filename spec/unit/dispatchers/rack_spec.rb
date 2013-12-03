
require 'spec_helper'

describe Restfulness::Dispatchers::Rack do

  class RackExampleResource < Restfulness::Resource
    def get
      'rack_example_result'
    end
  end

  let :klass do
    Restfulness::Dispatchers::Rack
  end

  let :app do
    Class.new(Restfulness::Application) {
      routes do
        add 'projects', RackExampleResource 
      end
    }.new
  end

  let :obj do
    klass.new(app)
  end

  let :env do
    {
      'REQUEST_METHOD'  => 'GET',
      'SCRIPT_NAME'     => '',
      'PATH_INFO'       => '/projects?query=test',
      'QUERY_STRING'    => '',
      'SERVER_NAME'     => 'localhost',
      'SERVER_PORT'     => '3000',
      'SERVER_PROTOCOL' => 'HTTP/1.1',
      'rack.url_scheme' => 'http',
      'REMOTE_ADDR'     => '192.168.1.23',
      'HTTP_CONTENT_TYPE' => 'application/json',
      'HTTP_X_AUTH_TOKEN' => 'foobartoken',
      'HTTP_USER_AGENT'   => 'Some Navigator',
    }
  end

  describe "#call" do

    it "should handle basic call and return response" do
      res = obj.call(env)
      res[0].should eql(200)
      res[1].should be_a(Hash)
      res[2].first.should eql('rack_example_result')
    end


  end

  describe "#parse_action (protected)" do

    it "should convert main actions to symbols" do
      actions = ['DELETE', 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'OPTIONS']
      actions.each do |action|
        val = obj.send(:parse_action, action)
        val.should eql(action.downcase.to_sym)
      end
    end

    it "should raise error if action unrecognised" do
      expect {
        obj.send(:parse_action, 'FOOO')
      }.to raise_error(Restfulness::HTTPException)
    end

  end

  describe "#prepare_headers (protected)" do

    it "should parse headers from environment" do
      res = obj.send(:prepare_headers, env)
      res[:content_type].should eql('application/json')
      res[:x_auth_token].should eql('foobartoken')
    end
  end

  describe "#prepare_request (protected)" do

    it "should prepare request object with main fields" do
      req = obj.send(:prepare_request, env)

      req.uri.should be_a(URI)
      req.action.should eql(:get)
      req.body.should be_nil
      req.headers.keys.should include(:x_auth_token)
      req.remote_ip.should eql('192.168.1.23')
      req.user_agent.should eql('Some Navigator')

      req.query.should_not be_empty
      req.query[:query].should eql('test')

      req.headers[:content_type].should eql('application/json')
    end

  end

end
