
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
      obj.router.should eql(klass.router)
    end
  end

  describe "#call" do
    it "should build rack app and call with env" do
      env = {}
      obj = klass.new
      app = double(:app)
      app.should_receive(:call).with(env)
      obj.should_receive(:build_rack_app).and_return(app)
      obj.call(env)
    end
  end

  describe "#build_rack_app (protected)" do
    it "should build a new rack app with middlewares" do
      obj = klass.new
      obj.class.middlewares << Rack::ShowExceptions
      app = obj.send(:build_rack_app)
      app.should be_a(Rack::Builder)
      # Note, this might brake if Rack changes!
      app.instance_variable_get(:@use).first.call.should be_a(klass.middlewares.first)
      app.instance_variable_get(:@run).should be_a(Restfulness::Dispatchers::Rack)
    end
  end

  describe ".routes" do

    context "basic usage" do
      it "should build a new router with block" do
        klass.router.should_not be_nil
        klass.router.should be_a(Restfulness::Router)
      end

      it "should be accessable from instance" do
        obj = klass.new
        obj.router.should eql(klass.router)
      end

      it "should pass block to Router instance" do
        block = lambda { }
        Restfulness::Router.should_receive(:new).with(&block)
        Class.new(Restfulness::Application) do
          routes &block
        end
      end
    end

  end

  describe ".middlewares" do
    it "should provide empty array of middlewares" do
      klass.middlewares.should be_a(Array)
      klass.middlewares.should be_empty
    end
  end

  describe ".logger" do
    it "should return main logger" do
      klass.logger.should eql(Restfulness.logger)
    end
  end

  describe ".logger=" do
    it "should set main logger" do
      orig = Restfulness.logger
      logger = double(:Logger)
      klass.logger = logger
      Restfulness.logger.should eql(logger)
      Restfulness.logger = orig
    end
  end


end
