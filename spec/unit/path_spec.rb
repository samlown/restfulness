require 'spec_helper'

describe Restfulness::Path do

  class PathResource < Restfulness::Resource
  end

  let :klass do
    Restfulness::Path
  end
  let :route_class do
    Restfulness::Route
  end
  let :resource_class do
    PathResource
  end
  let :simple_route do
    route_class.new('project', resource_class)
  end
  let :complex_route do
    route_class.new('project', :project_id, 'status', resource_class)
  end

  describe "#initialize" do
    
    it "should assign route" do
      obj = klass.new(simple_route, '/project')
      expect(obj.route).to eql(simple_route)
    end

    context "simple paths" do
      it "should prepare basic path" do
        obj = klass.new(simple_route, '/project')
        expect(obj.components).to eql(['project'])
        expect(obj.params[:id]).to be_nil
      end

      it "should prepare irregular path components" do
        obj = klass.new(simple_route, '/project/')
        expect(obj.components).to eql(['project'])
      end

      it "should include id" do
        obj = klass.new(simple_route, '/project/12345')
        expect(obj.components).to eql(['project', '12345'])
        expect(obj.params[:id]).to eql('12345')
      end
    end


    context "complex paths" do
      it "should prepare path" do
        obj = klass.new(complex_route, '/project/12345/status')
        expect(obj.components).to eql(['project', '12345', 'status'])
        expect(obj.params[:project_id]).to eql('12345')
      end

      it "should handle end id" do
        obj = klass.new(complex_route, '/project/12345/status/23456')
        expect(obj.components).to eql(['project', '12345', 'status', '23456'])
        expect(obj.params[:project_id]).to eql('12345')
        expect(obj.params[:id]).to eql('23456')
      end
    end
  end

  describe "#to_s" do
    it "should provide simple string" do
      obj = klass.new(complex_route, '/project/12345/status/23456')
      expect(obj.to_s).to eql('/project/12345/status/23456')
    end
  end

  describe "#[]" do
    let :obj do
      obj = klass.new(complex_route, '/project/12345/status/23456')
    end
    it "should grant access to components by index" do
      expect(obj[0]).to eql('project')
      expect(obj[1]).to eql('12345')
      expect(obj[2]).to eql('status')
      expect(obj[3]).to eql('23456')
      expect(obj[4]).to be_nil
    end
    it "should grant access to path parameters by symbol" do
      expect(obj[:project_id]).to eql('12345')
      expect(obj[:id]).to eql('23456')
    end
  end

end
