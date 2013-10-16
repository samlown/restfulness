
require 'spec_helper'

describe Restfulness::Dispatchers::Rack do

  let :klass do
    Restfulness::Dispatchers::Rack
  end

  let :app do
    Class.new(Restfulness::Application).new
  end

  let :obj do
    klass.new(app)
  end

  let :env do
    {
      'REQUEST_METHOD' => 'GET',
      'SCRIPT_NAME'    => 'projects',
      'PATH_INFO'      => 'projects',
      'QUERY_STRING'   => '',
      'SERVER_NAME'    => 'localhost',
      'SERVER_PORT'    => '3000',
      'HTTP_CONTENT_TYPE' => 'application/json'
    }
  end

  describe "#" do

  end

end
