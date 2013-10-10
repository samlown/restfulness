# Restfulness

Because REST APIs are all about resources, not routes.

## Introduction

Restfulness is an attempt to create a Ruby library that helps create truly REST based APIs to your services. The focus is placed on performing HTTP actions on resources via specific routes, as opposed to the current convention of assigning routes and HTTP actions to methods or blocks of code. The difference is subtle, but makes for a much more natural approach to building APIs.

The current version is very minimal, as it only support JSON content types, and does not have more advanced commonly used HTTP features like sessions or cookies. For most APIs this should be sufficient.

To try and highlight the diferences between Restfulness and other libraries, lets have a look at a couple of examples.

[Grape](https://github.com/intridea/grape) is a popular library for creating APIs in a "REST-like" manor. Here is a simplified section of code from their site:

```ruby
module Twitter
  class API < Grape::API

    version 'v1', using: :header, vendor: 'twitter'
    format :json

    resource :statuses do

      desc "Return a public timeline."
      get :public_timeline do
        Status.limit(20)
      end

      desc "Return a personal timeline."
     get :home_timeline do
        authenticate!
        current_user.statuses.limit(20)
      end

      desc "Return a status."
      params do
        requires :id, type: Integer, desc: "Status id."
      end
      route_param :id do
        get do
          Status.find(params[:id])
        end
      end

    end

  end
end

```

The focus in Grape is to construct an API by building up a route hierarchy where each HTTP action is tied to a specific ruby block. Resources are mentioned, but they're used more for structure or route-seperation, than a meaningful object.

Restfulness takes a different approach. The following example attempts to show how you might provide a similar API:

```ruby
class TwitterAPI < Restfullness::Application
  routes do
    add 'status',             StatusResource
    add 'timeline', 'public', PublicTimelineResource
    add 'timeline', 'home',   HomeTimelineResource
  end
end

class StatusResource < Restfulness::Resource
  def get
    Status.find(request.path[:id])
  end
end

class PublicTimelineResource < Restfulness::Resource
  def get
    Status.limit(20)
  end
end

# Authentication requires more cowbell, so assume the ApplicationResource is already defined
class HomeTimelineResource < ApplicationResource
  def authorized?
    authenticate!
  end
  def get
    current_user.statuses.limit(20)
  end
end

```

Resources are now important. I, for one, welcome our new resource overloads. They're a clear and consise way of separating logic between different classes, so an individual model has nothing to do with a collection of models, even if the same model may be provided in the result set.


## Installation

Add this line to your application's Gemfile:

    gem 'restfulness'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install restfulness

## Usage

### Defining an Application

A Restfulness application is a Rack application whose main function is to define the routes that will forward requests on a specific path to a resource. Your applications inherit from the `Restfulness::Application` class. Here's a simple example:

```ruby
class MyAppAPI < Restfulness::Application
  routes do
    add 'project',  ProjectResource
    add 'projects', ProjectsResource
  end
end

```

An application is designed to be included in your Rails, Sinatra, or other Rack project, simply include a new instance of your application in the `config.ru` file:

```ruby
run Rack::URLMap.new(
  "/"       => MyRailsApp::Application,
  "/api"    => MyAppAPI.new.dispatcher
)
```

By default, Restfulness comes with a Rack compatible dispatcher, but in the future it might make sense to add others.

### Routes

The aim of routes in Restfulness are to be stupid simple. These are the basic rules:

 * Each route is an array that forms a path when joined with `/`.
 * Order is important.
 * Strings are matched directly.
 * Symbols match anything, and are accessible as path attributes.
 * Every route automically gets an :id parameter at the end, that may or may not be null.

Lets see a few examples:

```ruby
routes do
  # Simple route to access a project, access with:
  #   * PUT /project
  #   * GET /project/1234
  add 'project',  ProjectResource

  # Parameters are also supported.
  # Access the project id using `request.path[:project_id]`
  add 'project', :project_id, 'status', ProjectStatusResource
end
```



### Resources

Resources are like Controllers in a Rails project. They handle the basic HTTP actions using methods that match the same name as the action.

Resources also have support for callbacks. These have similar objectives to the callbacks used in [Ruby Webmachine](https://github.com/seancribbs/webmachine-ruby) that control the flow of the application using HTTP events.


### Requests

All resource instances have access to a `Request` object via the `#request` method, much like you'd find in a Rails project. It provides access to the details including in the HTTP request, including headers, the request URL, path entries, the query, body and/or parameters.

Restfulness takes a slightly different, more methodical, approach to handling paths, queries, and parameters. Rails controllers will typically mash everything together into a `params` hash. While this is convenient for most use cases, it makes it much more difficult to separate values from different contexts. The result is that your controllers in Rails end up requiring a hash containing `:object` that points to the attributes you want to store, despite having already defined this information in the controllers URL. Backbone.js developers will have notices the pain in handling this as serialized Backbone Models by default do not include a wrapper key.

The following key methods are provided in a request object for dealing with parameters:

```ruby
# A URI object
request.uri                # #<URI::HTTPS:0x00123456789 URL:https://example.com/somepath?x=y>

# Basic request path
request.path.to_s          # '/project/123456'
request.path               # ['project', '123456']
request.path[:id]          # '123456'
request.path[0]            # 'project

# More complex request path, from route: ['project', :project_id, 'task']
request.path.to_s          # '/project/123456/task/234567'
request.path               # ['project', '123456', 'task', '234567']
request.path[:id]          # '234567'
require.path[:project_id]  # '123456'
require.path[2]            # 'task'

# The request query
request.query              # {:page => 1} - Hash with indifferent access
request.query[:page]       # 1

# Request body
request.body               # "{'key':'value'}" - string payload

# Request params
request.params             # {'key' => 'value'} - usually a JSON deserialized object
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write your code and test the socks off it!
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
