
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
      expect(res[0]).to eql(200)
      expect(res[1]).to be_a(Hash)
      expect(res[2].first).to eql('rack_example_result')
    end


  end

  describe "#parse_action (protected)" do

    it "should convert main actions to symbols" do
      actions = ['DELETE', 'GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'OPTIONS']
      actions.each do |action|
        val = obj.send(:parse_action, env, action)
        expect(val).to eql(action.downcase.to_sym)
      end
    end

    it "should raise error if action unrecognised" do
      expect {
        obj.send(:parse_action, env, 'FOOO')
      }.to raise_error(Restfulness::HTTPException)
    end

    it "should override the action if the override header is present" do
      env['HTTP_X_HTTP_METHOD_OVERRIDE'] = 'PATCH'
      expect(obj.send(:parse_action, env, 'POST')).to eql(:patch)
    end

    it "should handle junk in action override header" do
      env['HTTP_X_HTTP_METHOD_OVERRIDE'] = ' PatCH '
      expect(obj.send(:parse_action, env, 'POST')).to eql(:patch)
    end

  end

  describe "#prepare_headers (protected)" do

    it "should parse headers from environment" do
      res = obj.send(:prepare_headers, env)
      expect(res[:content_type]).to eql('application/json')
      expect(res[:x_auth_token]).to eql('foobartoken')
    end
  end

  describe "#prepare_request (protected)" do

    it "should prepare request object with main fields" do
      req = obj.send(:prepare_request, env)

      expect(req.uri).to be_a(URI)
      expect(req.action).to eql(:get)
      expect(req.body).to be_nil
      expect(req.headers.keys).to include(:x_auth_token)
      expect(req.remote_ip).to eql('192.168.1.23')
      expect(req.user_agent).to eql('Some Navigator')
      expect(req.env).to be env

      expect(req.query).not_to be_empty
      expect(req.query[:query]).to eql('test')

      expect(req.headers[:content_type]).to eql('application/json')
    end

    it "should handle the body stringio" do
      env['rack.input'] = StringIO.new("Some String")

      req = obj.send(:prepare_request, env)
      expect(req.body.read).to eql('Some String')
    end

    it "should rewind the body stringio" do
      env['rack.input'] = StringIO.new("Some String")
      env['rack.input'].read

      req = obj.send(:prepare_request, env)
      expect(req.body.read).to eql('Some String')
    end


  end

end
