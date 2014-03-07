
require 'spec_helper'

describe Restfulness::Router do

  class RouterResource < Restfulness::Resource
  end

  class SecondRouterResource < Restfulness::Resource
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
    it "should accept block as scope" do
      obj = klass.new
      obj.add 'project', RouterResource do
        add 'examples', SecondRouterResource
      end
      route = obj.routes.first
      route.resource.should eql(SecondRouterResource)
      route.path.should eql(['project', 'examples'])
      route = obj.routes.last
      route.resource.should eql(RouterResource)
      route.path.should eql(['project'])
    end
  end

  describe "#scope" do
    it "should append to the current_scope attribute in block and reset" do
      obj = klass.new
      subscope = nil # Can't use rspec inside instance eval!
      obj.scope 'api' do
        subscope = current_scope
      end
      subscope.should eql(['api'])
      obj.current_scope.should eql([])
    end 

    it "should add scope properties to add call" do
      obj = klass.new
      res = resource
      obj.scope 'api' do
        add 'projects', res
      end
      route = obj.routes.first
      route.path.should eql(['api', 'projects'])
    end

    it "should allow for scopes within scopes" do
      obj = klass.new
      res = resource
      subscope = nil
      subsubscope = nil
      obj.scope 'api' do
        scope 'projects' do
          add 'active', res
          subsubscope = current_scope
        end
        subscope = current_scope
      end
      subsubscope.should eql(['api', 'projects'])
      subscope.should eql(['api'])
      obj.current_scope.should eql([])
      route = obj.routes.first
      route.path.should eql(['api', 'projects', 'active'])
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
