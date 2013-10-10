require 'spec_helper'

describe Restfulness::Path do

  let :klass do
    Restfulness::Path
  end
  let :route_class do
    Restfulness::Route
  end
  let :resource_class do
    Class.new(Restfulness::Resource) do
      # nothing here
    end
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
      obj.route.should eql(simple_route)
    end

    context "simple paths" do
      it "should prepare basic path" do
        obj = klass.new(simple_route, '/project')
        obj.components.should eql(['project'])
        obj.params[:id].should be_nil
      end

      it "should prepare irregular path components" do
        obj = klass.new(simple_route, '/project/')
        obj.components.should eql(['project'])
      end

      it "should include id" do
        obj = klass.new(simple_route, '/project/12345')
        obj.components.should eql(['project', '12345'])
        obj.params[:id].should eql('12345')
      end
    end


    context "complex paths" do
      it "should prepare path" do
        obj = klass.new(complex_route, '/project/12345/status')
        obj.components.should eql(['project', '12345', 'status'])
        obj.params[:project_id].should eql('12345')
      end

      it "should handle end id" do
        obj = klass.new(complex_route, '/project/12345/status/23456')
        obj.components.should eql(['project', '12345', 'status', '23456'])
        obj.params[:project_id].should eql('12345')
        obj.params[:id].should eql('23456')
      end
    end
  end

  describe "#to_s" do
    it "should provide simple string" do
      obj = klass.new(complex_route, '/project/12345/status/23456')
      obj.to_s.should eql('/project/12345/status/23456')
    end
  end

  describe "#[]" do
    let :obj do
      obj = klass.new(complex_route, '/project/12345/status/23456')
    end
    it "should grant access to components by index" do
      obj[0].should eql('project')
      obj[1].should eql('12345')
      obj[2].should eql('status')
      obj[3].should eql('23456')
      obj[4].should be_nil
    end
    it "should grant access to path parameters by symbol" do
      obj[:project_id].should eql('12345')
      obj[:id].should eql('23456')
    end
  end

end
