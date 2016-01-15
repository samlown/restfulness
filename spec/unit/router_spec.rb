
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
      expect(obj.routes).to eql([])
    end

    it "should prepare routes with instance eval block" do
      obj = klass.new do
        @foo = 'bar'
      end
      expect(obj.instance_variable_get(:@foo)).to eql('bar')
    end

  end

  describe "#add" do
    it "should add route to object" do
      obj = klass.new
      obj.add 'projects', resource
      expect(obj.routes.length).to eql(1)
      route = obj.routes.first
      expect(route).to be_a(Restfulness::Route)
      expect(route.path).to eql(['projects'])
    end
    it "should accept block as scope" do
      obj = klass.new
      obj.add 'project', RouterResource do
        add 'examples', SecondRouterResource
      end
      route = obj.routes.first
      expect(route.resource).to eql(SecondRouterResource)
      expect(route.path).to eql(['project', 'examples'])
      route = obj.routes.last
      expect(route.resource).to eql(RouterResource)
      expect(route.path).to eql(['project'])
    end
  end

  describe "#scope" do
    it "should append to the current_scope attribute in block and reset" do
      obj = klass.new
      subscope = nil # Can't use rspec inside instance eval!
      obj.scope 'api' do
        subscope = current_scope
      end
      expect(subscope).to eql(['api'])
      expect(obj.current_scope).to eql([])
    end 

    it "should add scope properties to add call" do
      obj = klass.new
      res = resource
      obj.scope 'api' do
        add 'projects', res
      end
      route = obj.routes.first
      expect(route.path).to eql(['api', 'projects'])
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
      expect(subsubscope).to eql(['api', 'projects'])
      expect(subscope).to eql(['api'])
      expect(obj.current_scope).to eql([])
      route = obj.routes.first
      expect(route.path).to eql(['api', 'projects', 'active'])
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
      expect(route).not_to be_nil
      expect(route.path).to eql(['projects'])
    end

    it "should determine the route for a simple path with id" do
      route = obj.route_for("/projects")
      expect(route).not_to be_nil
      expect(route.path).to eql(['projects'])
    end

    it "should determine the route for a simple path with id and end /" do
      route = obj.route_for("/projects/12345/")
      expect(route).not_to be_nil
      expect(route.path).to eql(['projects'])
    end

    it "should determine the route for a simple path with end /" do
      route = obj.route_for("/projects/")
      expect(route).not_to be_nil
      expect(route.path).to eql(['projects'])
    end

    it "should determine route for more complex path" do
      route = obj.route_for("/project/1235/status/1234")
      expect(route).not_to be_nil
      expect(route.path).to eql(['project', :project_id, 'status'])
    end

    it "should return nil if not matched" do
      route = obj.route_for("/projects/1235/statuses/")
      expect(route).to be_nil
    end

    it "should match empty path" do
      route = obj.route_for("/")
      expect(route.path).to eql([])
    end

    it "should match path with single parameter" do
      route = obj.route_for("/something")
      expect(route.path).to eql([:page])
    end
  end


end
