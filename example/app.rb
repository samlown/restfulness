
require 'restfulness'

$projects = []

Project = Class.new(HashWithIndifferentAccess)

class ProjectResource < Restfulness::Resource
  def exists?
    !project.nil?
  end
  def get
    project
  end
  def post
    $projects << Project.new(request.params)
  end
  def patch
    project.update(request.params)
  end
  def delete
    $projects.delete(project)
  end
  protected
  def project
    $projects.find{|p| p[:id] == request.path[:id]}
  end
end

class ProjectsResource < Restfulness::Resource
  def get
    $projects
  end
end


class ExampleApp < Restfulness::Application
  routes do
    add 'project', ProjectResource
    add 'projects', ProjectsResource
  end
end
