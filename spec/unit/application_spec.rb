
require 'spec_helper'

describe Restfulness::Application do

  let :klass do
    Class.new(Restfulness::Application) do
      routes do
        # nothing
      end
    end
  end

  describe "#router" do
    it "should access class's router" do
      obj = klass.new
      expect(obj.router).to eql(klass.router)
    end
  end

  describe "#call" do
    it "should build rack app and call with env" do
      env = {}
      obj = klass.new
      app = double(:app)
      expect(app).to receive(:call).with(env)
      expect(obj).to receive(:build_rack_app).and_return(app)
      obj.call(env)
    end
  end

  describe "#build_rack_app (protected)" do
    it "should build a new rack app with middlewares" do
      obj = klass.new
      obj.class.middlewares << Rack::ShowExceptions
      app = obj.send(:build_rack_app)
      expect(app).to be_a(Rack::Builder)
      # Note, this might brake if Rack changes!
      expect(app.instance_variable_get(:@use).first.call).to be_a(klass.middlewares.first)
      expect(app.instance_variable_get(:@run)).to be_a(Restfulness::Dispatchers::Rack)
    end
  end

  describe ".routes" do

    context "basic usage" do
      it "should build a new router with block" do
        expect(klass.router).not_to be_nil
        expect(klass.router).to be_a(Restfulness::Router)
      end

      it "should be accessable from instance" do
        obj = klass.new
        expect(obj.router).to eql(klass.router)
      end

      it "should pass block to Router instance" do
        block = lambda { }
        expect(Restfulness::Router).to receive(:new).with(no_args, &block)
        Class.new(Restfulness::Application) do
          routes &block
        end
      end
    end

  end

  describe ".middlewares" do
    it "should provide empty array of middlewares" do
      expect(klass.middlewares).to be_a(Array)
      expect(klass.middlewares).to be_empty
    end
  end

  describe ".logger" do
    it "should return main logger" do
      expect(klass.logger).to eql(Restfulness.logger)
    end
  end

  describe ".logger=" do
    it "should set main logger" do
      orig = Restfulness.logger
      logger = double(:Logger)
      klass.logger = logger
      expect(Restfulness.logger).to eql(logger)
      Restfulness.logger = orig
    end
  end


end
