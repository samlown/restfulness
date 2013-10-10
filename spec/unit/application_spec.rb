
require 'spec_helper'

describe Restfulness::Application do

  describe "#initialize" do
    it "should build a dispatcher" do
      klass = Class.new(Restfulness::Application)
      obj = klass.new
      obj.dispatcher.should_not be_nil
      obj.dispatcher.is_a?(Restfulness::Dispatcher).should be_true
    end
  end

  describe ".routes" do

    context "basic usage" do
      let :klass do
        Class.new(Restfulness::Application) do
          routes do
            # nothing
          end
        end
      end

      it "should build a new router with block" do
        klass.router.should_not be_nil
        klass.router.should be_a(Restfulness::Router)
      end

      it "should be accessable from instance" do
        obj = klass.new
        obj.router.should eql(klass.router)
      end

      it "should pass options and block to Router instance" do
        block = lambda { }
        Restfulness::Router.should_receive(:new).with({:test => :foo}, &block)
        Class.new(Restfulness::Application) do
          routes :test => :foo, &block
        end
      end
    end

  end


end
