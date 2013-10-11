
require 'spec_helper'

describe Restfulness::Route do

  let :klass do
    Restfulness::Route
  end

  let :resource do
    Class.new(Restfulness::Resource)
  end

  describe "#initialize" do

    it "should assign basic path and resource" do
      obj = klass.new('project', resource)
      obj.path.should eql(['project'])
      obj.resource.should eql(resource)
    end

    it "should assign path with symbols" do
      obj = klass.new('project', :project_id, 'states', resource)
      obj.path.should eql(['project', :project_id, 'states']) 
    end

    it "should remove :id from end" do
      obj = klass.new('project', :project_id, 'states', :id, resource)
      obj.path.should eql(['project', :project_id, 'states'])
    end

    it "should handle numbers in path" do
      obj = klass.new('project', 120, resource)
      obj.path.should eql(['project', 120])
    end

    it "should raise error if resource not included" do
      expect {
        klass.new('project')
      }.to raise_error(/missing resource/)
    end

  end

  describe "#build_path" do
    it "should build a new path object including self" do
      obj = klass.new('project', resource)
      path = obj.build_path("/project/12345")
      path.should be_a(Restfulness::Path)
      path.route.should eql(obj)
    end
  end

  describe "#handles?" do
    
  end

  describe "#build_resource" do

  end

end
