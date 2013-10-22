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

I, for one, welcome our new resource overloads. They're a clear and consise way of separating logic between different classes, so an individual model has nothing to do with a collection of models, even if the same model may be provided in the result set.


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
  "/api"    => MyAppAPI.new
)
```

If you want to run Restfulness standalone, simply create a `config.ru` that will load up your application:

```ruby
require 'my_app'
run MyApp.new
```

You can then run this with rackup:

```
bundle exec rackup
```

For a very simple example project, checkout the `/example` directory in the source code.


### Routes

The aim of routes in Restfulness are to be stupid simple. These are the basic rules:

 * Each route is an array that forms a path when joined with `/`.
 * Order is important.
 * Strings are matched directly.
 * Symbols match anything, and are accessible as path attributes.
 * Every route automically gets an :id parameter at the end, that may or may not have a null value.

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

Resources are like Controllers in a Rails project. They handle the basic HTTP actions using methods that match the same name as the action. The result of an action is serialized into a JSON object automatically. The actions supported by a resource are:

 * `get`
 * `head`
 * `post`
 * `patch`
 * `put`
 * `delete`
 * `options` - this is the only action provded by default

When creating your resource, simply define the methods you'd like to use and ensure each has a result:

```ruby
class ProjectResource < Restfulness::Resource
  # Return the basic object
  def get
    project
  end

  # Update the existing object with some new attributes
  def patch
    project.update(params)
  end

  protected

  def project
    @project ||= Project.find(request.path[:id])
  end
end
```

Checking which methods are available is also possible by sending an `OPTIONS` action. Using the above resource as a base:

    curl -v -X OPTIONS http://localhost:9292/project

Will include an `Allow` header that lists: "GET, PUT, OPTIONS".

Resources also have support for simple set of built-in callbacks. These have similar objectives to the callbacks used in [Ruby Webmachine](https://github.com/seancribbs/webmachine-ruby) that control the flow of the application using HTTP events.

The supported callbacks are:

 * `exists?` - True by default, not called in create actions like POST.
 * `authorized?` - True by default, is the current user valid?
 * `allowed?` - True by default, does the current have access to the resource?
 * `last_modified` - The date of last update on the model, only called for GET and HEAD requests. Validated against the `If-Modified-Since` header.
 * `etag` - Unique identifier for the object, only called for GET and HEAD requests. Validated against the `If-None-Match` header.

To use them, simply override the method:

```ruby
class ProjectResource < Restfulness::Resource
  # Does the project exist? only called in GET request
  def exists?
    !project.nil?
  end

  # Return a 304 status if the client can used a cached resource
  def last_modified
    project.updated_at.to_s
  end

  # Return the basic object
  def get
    project
  end

  # Update the object
  def post
    Project.create(params)
  end

  protected

  def project
    @project ||= Project.find(request.path[:id])
  end
end
```


### Requests

All resource instances have access to a `Request` object via the `#request` method, much like you'd find in a Rails project. It provides access to the details including in the HTTP request: headers, the request URL, path entries, the query, body and/or parameters.

Restfulness takes a slightly different approach to handling paths, queries, and parameters. Rails and Sinatra apps will typically mash everything together into a `params` hash. While this is convenient for most use cases, it makes it much more difficult to separate values from different contexts. The effects of this are most noticable if you've ever used Models Backbone.js or similar Javascript library. By default a Backbone Model will provide attributes without a prefix in the POST body, so to be able to differenciate between query, path and body parameters you need to ignore the extra attributes, or hack a part of your code to re-add a prefix.

The following key methods are provided in a request object:

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

## Error Handling

If you want your application to return anything other than a 200 (or 202) status, you have a couple of options that allow you to send codes back to the client.

The easiest method is probably just to update the `response` code. Take the following example where we set a 403 response and the model's errors object in the payload:

```ruby
class ProjectResource < Restfulness::Resource
  def patch
    if project.update_attributes(request.params)
      project
    else
      response.status = 403
      project.errors
    end
  end
end
```

The favourite method in Restfulness however is to use the `HTTPException` class and helper methods that will raise the error for you. For example:

```ruby
class ProjectResource < Restfulness::Resource
  def patch
    unless project.update_attributes(request.params)
      forbidden!(project.errors)
    end
    project
  end
end
```

The `forbidden!` bang method will call the `error!` method, which in turn will raise an `HTTPException` with the appropriate status code. Exceptions are permitted to include a payload also, so you could override the `error!` method if you wished with code that will automatically re-format the payload. Another example:

```ruby
# Regular resource
class ProjectResource < ApplicationResource
  def patch
    unless project.update_attributes(request.params)
      forbidden!(project) # only send the project object!
    end
    project
  end
end

# Main Application Resource
class ApplicationResource < Restfulness::Resource
  # Overwrite the regular error handler so we can provide
  # our own format.
  def error!(status, payload = "", opts = {})
    case payload
    when ActiveRecord::Base # or your favourite ORM
      payload = {
        :errors => payload.errors.full_messages
      }
    end
    super(status, payload, opts)
  end
end

```

This can be a really nice way to mold your errors into a standard format. All HTTP exceptions generated inside resources will pass through `error!`, even those that a triggered by a callback. It gives a great way to provide your own more complete result, or even just resort to a simple string.

The currently built in error methods are:

 * `not_modified!`
 * `bad_request!`
 * `unauthorized!`
 * `payment_required!`
 * `forbidden!`
 * `resource_not_found!`
 * `request_timeout!`
 * `conflict!`
 * `gone!`
 * `unprocessable_entity!`

If you'd like to see me more, please send us a pull request! Failing that, you can create your own by writing something along the lines of:

```ruby
def im_a_teapot!(payload = "")
  error!(418, payload)
end
```


## Caveats and TODOs

Restfulness is still very much a work in progress. Here is a list of things that we'd like to improve or fix:

 * Support for more serializers and content types, not just JSON.
 * Support path methods for automatic URL generation.
 * Support redirect exceptions.
 * Reloading is a PITA (see note below).
 * Needs more functional testing.
 * Support for before and after filters in resources, although I'm slightly aprehensive about this.

## Reloading

Reloading is complicated. Unfortunately we're all used to the way Rails projects magically reload changed files so you don't have to restart the server after each change.

If you're using Restfulness as a standalone project, we recommend using a rack extension like [Shotgun](https://github.com/rtomayko/shotgun).

If you're adding Restfulness to a Rails project, you can take advantage of the `ActionDispatch::Reloader` rack middleware. Simply include it in the application definition:

```ruby
class MyAPI < Restfulness::Application
  if Rails.env.development?
    middlewares << ActionDispatch::Relaoder
  end
  routes do
    # etc. etc.
  end
```

We're still working on ways to improve this. If you have any ideas, please send me a pull request!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write your code and test the socks off it!
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Contributors

Restfulness was created by Sam Lown <me@samlown.com> as a solution for building simple APIs at [Cabify](http://www.cabify.com).


## History

### 0.2.1 - October 22, 2013

 * Removing some unnecessary logging and using Rack::CommonLogger.
 * Improving some test coverage. 
 * Supporting user agent in requests.
 * Supporting PATCH method in resources.

### 0.2.0 - October 17, 2013

 * Refactoring error handling and reporting so that it is easier to use and simpler.

### 0.1.0 - October 16, 2013

First release!


