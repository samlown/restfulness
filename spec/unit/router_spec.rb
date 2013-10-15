
require 'spec_helper'

describe Restfulness::Router do

  class RouterResource < Restfulness::Resource
  end

  let :klass do
    Restfulness::Router
  end

  let :resource do
    RouterResource
  end

  describe "#initialize" do

    it "should prepare routes" do
      obj = klass.new
      obj.routes.should eql([])
    end

    it "should prepare routes with instance eval block" do
      block = lambda {}
      obj = klass.new do
        @foo = 'bar'
      end
      obj.instance_variable_get(:@foo).should eql('bar')
    end

  end

  describe "#add" do
    it "should add route to object" do
      obj = klass.new
      obj.add 'projects', resource
      obj.routes.length.should eql(1)
      route = obj.routes.first
      route.should be_a(Restfulness::Route)
      route.path.should eql(['projects'])
    end
  end

  describe "#route_for" do
    let :obj do
      res = resource
      klass.new do
        add 'projects', res
        add 'project', :project_id, 'status', res
        add :page, res
        add res
      end
    end

    it "should determine the route for a simple path" do
      route = obj.route_for("/projects")
      route.should_not be_nil
      route.path.should eql(['projects'])
    end

    it "should determine the route for a simple path with id" do
      route = obj.route_for("/projects")
      route.should_not be_nil
      route.path.should eql(['projects'])
    end

    it "should determine the route for a simple path with id and end /" do
      route = obj.route_for("/projects/12345/")
      route.should_not be_nil
      route.path.should eql(['projects'])
    end

    it "should determine the route for a simple path with end /" do
      route = obj.route_for("/projects/")
      route.should_not be_nil
      route.path.should eql(['projects'])
    end

    it "should determine route for more complex path" do
      route = obj.route_for("/project/1235/status/1234")
      route.should_not be_nil
      route.path.should eql(['project', :project_id, 'status'])
    end

    it "should return nil if not matched" do
      route = obj.route_for("/projects/1235/statuses/")
      route.should be_nil
    end

    it "should match empty path" do
      route = obj.route_for("/")
      route.path.should eql([])
    end

    it "should match path with single parameter" do
      route = obj.route_for("/something")
      route.path.should eql([:page])
    end
  end


end
