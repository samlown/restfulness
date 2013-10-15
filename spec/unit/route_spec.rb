
require 'spec_helper'

describe Restfulness::Route do

  class ATestResource < Restfulness::Resource
  end

  let :klass do
    Restfulness::Route
  end

  let :resource do
    ATestResource
  end

  describe "#initialize" do

    it "should assign basic path and resource" do
      obj = klass.new('project', resource)
      obj.path.should eql(['project'])
      obj.resource_name.should eql(resource.to_s)
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

    it "should accept classes as strings" do
      expect {
        obj = klass.new('project', resource.to_s)
      }.to_not raise_error
    end

    it "should raise name error if resource does not exist" do
      expect {
        klass.new('project')
      }.to raise_error(NameError)
    end

    it "should raise name error if no arguments" do
      expect {
        klass.new()
      }.to raise_error(ArgumentError)
    end

  end

  describe "#resource" do
    it "should provide constant to class" do
      obj = klass.new('project', resource)
      obj.resource.should eql(resource)
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

    context "simple path" do
      let :obj do 
        klass.new('project', resource)
      end
      it "should return true for match" do
        obj.handles?(['project']).should be_true
      end
      it "should return true for match with id" do
        obj.handles?(['project', '12345']).should be_true
      end
      it "should return false for different name" do
        obj.handles?(['projects']).should be_false
      end
      it "should return false for matching start" do
        obj.handles?(['project', '12345', 'status']).should be_false
      end
    end

    context "catch all path" do
      let :obj do 
        klass.new(resource)
      end
      it "should matching empty path" do
        obj.handles?([]).should be_true
      end
      it "should matching empty path with id" do
        obj.handles?(['12345']).should be_true
      end
      it "shold not match extended URL" do
        obj.handles?(['foobar', '12345']).should be_false
      end
    end

    context "single variable path" do
      let :obj do 
        klass.new(:project_id, resource)
      end
      it "should matching anything" do
        obj.handles?(['foobar']).should be_true
      end
      it "should matching anything, with id" do
        obj.handles?(['foobar', '12345']).should be_true
      end
      it "shold not match extended URL" do
        obj.handles?(['foobar', 'status', '12345']).should be_false
      end
    end

    context "complex path" do
      let :obj do 
        klass.new('project', :project_id, 'status', resource)
      end
      it "should return true for match" do
        obj.handles?(['project', '1234', 'status']).should be_true
      end
      it "should return true for match with id" do
        obj.handles?(['project', '1234', 'status', '12345']).should be_true
      end
      it "should not match short path" do
        obj.handles?(['project']).should be_false
      end
      it "should not match path with different name" do
        obj.handles?(['project', '12345', 'statuses']).should be_false
      end
      it "should not match extended path" do
        obj.handles?(['project', '12345', 'status', '1234', 'test']).should be_false
      end

    end
    
  end

  describe "#build_resource" do

    it "should request a new resource" do
      obj = klass.new('project', resource)
      resource.should_receive(:new).with({}, {}).and_return(nil)
      obj.build_resource({}, {})
    end

  end

end
