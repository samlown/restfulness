# Restfulness

Because REST APIs are all about resources, not routes.

[![Build Status](https://travis-ci.org/samlown/restfulness.png)](https://travis-ci.org/samlown/restfulness)

## Introduction

Restfulness is a simple Ruby library for creating REST APIs. Each endpoint defined in the routing configuration refers to a resource class containing HTTP actions and callbacks. When an HTTP request is received, the callbacks are checked, and the appropriate action is called to provide a response.

When creating Restfulness, we had a set of objectives we wanted to achieve:

 * A true "resource" orientated interface.
 * Simple routing.
 * Fast.
 * JSON only responses.
 * Take advantage of HTTP flow control using callbacks.
 * Simple error handling, and "instant abort" exceptions.

Here's a code example of what the restfulness side of a rack application might look like:

```ruby
# The API definition, this matches incoming request paths to resources
class TwitterAPI < Restfullness::Application
  routes do
    scope 'api' do
      add 'task',      Tasks::ItemResource
      scope 'tasks' do
        add 'public',  Tasks::PublicResource
        add 'private', Tasks::PrivateResource
      end
    end
  end
end

# Modules are always a good idea to group resources
module Tasks
  # A simple resource for returning tasks
  class ItemResource < Restfulness::Resource
    # Callback to see if task exsists
    def exists?
      !!task
    end

    # Provide the task, if the #exists? call worked
    def get
      task  
    end

    # Create a new task, this will bypass the #exits? call
    def post
      Task.create(request.params)
    end

    # Update the task, and raise an error with error response if failed
    def patch
      task.update_attributes(request.params) || forbidden!(task.errors)
    end

    protected

    def task
      @task ||= Task.find(request.path[:id])
    end
  end

  # Simple resource that provides list of public tasks, that may be empty
  class PublicResource < Restfulness::Resource
    def get
      Task.public.limit(20)
    end
  end

  # Authorization requires additional code to authenticate the user
  class PrivateResource < Restfulness::Resource
    # If this fails, abort and return 401 Unauthorized response
    def authorized?
      !current_user
    end

    # Assuming authorized, attept to load tasks
    def get
      current_user.tasks.limit(20)
    end

    protected

    # Very simple example of authentication
    def current_user
      @current_user ||= authenticate_with_http_basic do |username, password|
        User.authenticate(username, password)
      end
    end
  end
end

```

Checkout the rest of this document for more of the details on the api, integration with your existing apps, and additional features.


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

If you're using Restulfness in a Rails project, you'll want to checkout the Reloading section below.


### Routes

The aim of routes in Restfulness are to be stupid simple. These are the basic rules:

 * Each route is an array that forms a path when joined with `/`.
 * Order is important.
 * Strings are matched directly.
 * Symbols match anything, and are accessible as path attributes.
 * Every route automatically gets an :id parameter at the end, that may or may not have a null value.
 * Scopes save repeating shared route array entries.

Lets see a few examples:

```ruby
routes do
  scope 'api' do
    # Simple route to access a project, access with:
    #   * PUT /api/project
    #   * GET /api/project/1234
    add 'project',  ProjectResource

    # Parameters are also supported.
    # Access the project id using `request.path[:project_id]`
    add 'project', :project_id, 'status', ProjectStatusResource

    # Scope's can be embedded
    scope 'journeys' do
      add 'active',     Journeys::ActiveResource
      add 'terminated', Journeys::TerminatedResource
    end
    
    # Add a general purpose list resource *after* scope
    add 'journeys', Journeys::ListResource
  end
end
```

The `add` router method can also except a block which will be interpreted as a scope. The following example will provide the same paths as the `journeys` scope and resource defined above. The most important factor to take into account is that the `Journeys::ListResource` will be added to the route **after** the `active` and `terminated` resources. Order is important!

```ruby
routes do
  scope 'api' do
    add 'journeys', Journeys::ListResource do
      add 'active',     Journeys::ActiveResource
      add 'terminated', Journeys::TerminatedResource
    end
  end
end
``` 


### Resources

Resources are like controllers in a Rails project. They handle the basic HTTP actions using methods that match the same name as the action. The result of an action is serialized into a JSON object automatically. The actions supported by a resource are:

 * `get`
 * `head`
 * `post`
 * `patch`
 * `put`
 * `delete`
 * `options` - this is the only action provided by default

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

 * `exists?` - True by default, not called in create actions like POST or PUT.
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

#### I18n in Resources

Restfulness uses the [http_accept_language](https://github.com/iain/http_accept_language) gem to automatically handle the `Accept-Language` header received from a client. After trying to make a match between the available locales, it will automatically set the `I18n.locale`. You can access the http_accept_language parser via the `request.http_accept_language` method.

For most APIs this should work great, especially for mobile applications where this header is automatically set by the phone. There may however be situations where you need a bit more control. If a user has a preferred language setting for example.

Resources contain two protected methods that can be overwritten. This is what they look like in the Restfulness code:

```ruby
protected

def locale
  request.http_accept_language.compatible_language_from(I18n.available_locales)
end

def set_locale
  I18n.locale = locale
end
```

The `Resource#set_locale` method is called before any of the other callbacks are handled. This is important as it allows the locale to be set before returning any translatable error messages.

Most users will probably just want to override the `Resource#locale` method and provide the appropriate locale for the request. If you are using a User object or similar, double check your authentication process as the default `authorized?` method will be called *after* the locale is prepared so that error responses are always in the requested language.

#### Authentication in Resources

Restfulness provides basic support for [HTTP Basic Authentication](http://en.wikipedia.org/wiki/Basic_access_authentication). To use, simply call the `authenticate_with_http_basic` method in your resource definition.

Here's an example with the authentication details in the code, you'd obviously want to use something a bit more advanced than this in production:

```ruby
def authorized?
  authenticate_with_http_basic do |username, password|
    username == 'user' && password == 'pass'
  end
end
```

The `request` object provided in the resource, described below, provides access to the HTTP `Authorization` header via the `Reqest#authorization` method. If you want to use an alternative authentication method you can use this to extract the details you might need. For example:

```ruby
def authorized?
  auth = request.authorization
  auth && (auth.schema == 'Token') && (auth.params == our_secret_token)
end
```

Digest authentication is not currently supported, but your contributions would be more than welcome. Checkout the [HttpAuthentication/basic.rb](blob/master/lib/restfulness/http_authentication/basic.rb) source for an example.

Restfulness doesn't make any provisions for requesting authentication from the client as in our experience most APIs don't need to offer this functionality. You can achieve the same effect however by providing the `WWW-Authenticate` header in the response. For example:

```ruby
def authorized?
  authorize_with_http_basic || request_authentication
end

def authorize_with_http_basic
  authenticate_with_http_basic do |username, password|
    username == 'user' && password == 'pass'
  end
end

def request_authentication
  response.headers['WWW-Authenticate'] = 'Basic realm="My Realm"'
  false
end
```

### Requests

All resource instances have access to a `Request` object via the `Resource#request` method, much like you'd find in a Rails project. It provides access to the details including in the HTTP request: headers, the request URL, path entries, the query, body and/or parameters.

Restfulness takes a slightly different approach to handling paths, queries, and parameters, as each has their own independent method. Rails and Sinatra will typically mash everything together into a `params` hash. While this is convenient for use cases involving a browser, it is less useful for APIs when body parameters should only contain attributes of the model managed by the resource. If you've ever used Models from Backbone.js or similar Javascript library you appreciate this. When saving a Model, Backbone.js assumes by default that attributes will be provided without a prefix in the POST body.

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
request.path[:project_id]  # '123456'
request.path[2]            # 'task'

# The request query
request.query              # {:page => 1} - Hash with indifferent access
request.query[:page]       # 1

# Request body
request.body               # "{'key':'value'}" - string payload

# Request params
request.params             # {'key' => 'value'} - usually a JSON de-serialized object

# Accept header object (nil if none!)
request.accept.version     # For "Accept: application/vnd.example.api+json;version=3", returns "3"

# Content Type object (nil if none!)
request.content_type.to_s  # Something like "application/json"
```

### Logging

By default, Restfulness uses `ActiveSupport::Logger.new(STDOUT)` as its logger.

To change the logger:

```ruby
Restfulness.logger = Rack::NullLogger.new(My::Api)
```

By default, any parameter with key prefix `password` will be sanitized in the log. To change the sensitive parameters:

```ruby
Restfulness.sensitive_params = [:password, :secretkey]
```

## Status Code and Error Handling

If you'd like your application to return anything other than a 200 status (or 204 for an empty payload), you can set it directly on the response object:

```ruby
class ProjectResource < Restfulness::Resource
  def get
    response.status = 203
    project
  end
end
```

The recommended approach in Restfulness however is to use the success status code helpers, for example:

```ruby
class ProjectResource < Restfulness::Resource
  def get
    non_authoritative(project) # Respond with 203
  end
  def put
    build_project
    created(project) # Respond with 201
  end
end
```

Any payload passed into the helper will be returned after setting the code.

Dealing with error responses (3XX, or 4XX codes) can also be dealt with using the `response` object. Take the following example where we set a 403 response and the model's errors object in the payload:

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

Continuing from the recommended approach for success helpers, Restfulness provides a `HTTPException` class and "bang" helper methods that will raise the error for you. For example:

```ruby
class ProjectResource < Restfulness::Resource
  def patch
    unless project.update_attributes(request.params)
      forbidden! project.errors
    end
    project
  end
end
```

The `forbidden!` bang method will call the `error!` method, which in turn will raise an `HTTPException` containing the appropriate status code. Exceptions are permitted to include a payload also, so you can override the `error!` method if you wished with code that will automatically re-format the payload. Another example:

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

This can be a really nice way to mold your errors into a standard format. All HTTP exceptions generated inside resources will pass through `error!`, even those that a triggered by a callback. It gives a great way to provide your own JSON error payload, or even just resort to a simple string.

The current built in success methods are:

 * `ok` - code 200, the default.
 * `created` - code 201.
 * `accepted` - code 202.
 * `non_authoritative_information` - code 203.
 * `non_authoritative` - code 203, same as previous, but a shorter method name.
 * `no_content` - code 204, default when no payload provided.
 * `reset_content` - code 205.

The current built in exception methods are:

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

If you'd like to see me more, please send us a pull request. Failing that, you can create your own by writing something along the lines of:

```ruby
def im_a_teapot!(payload = "")
  error!(418, payload)
end
```

## Reloading

We're all used to the way Rails projects magically reload files so you don't have to restart the server after each change. Depending on the way you use Restfulness in your project, this can be supported.

### The Rails Way

Using Restfulness in Rails is the easiest way to take advantage support reloading.

The recommended approach is to create two directories in your Rails projects `/app` path:

 * `/app/apis` can be used for defining your API route files, and
 * `/app/resources` for defining a tree of resource definition files.

Add the two paths to your rails auto-loading configuration in `/config/application.rb`, there will already be a sample in your config provided by Rails:

```ruby
# Custom directories with classes and modules you want to be autoloadable.
config.autoload_paths += %W( #{config.root}/app/resources #{config.root}/app/apis )
```

Your Resource and API files will now be auto-loadable from your Rails project. The next step is to update the Rails router to be able to find our API. Modify the `/config/routes.rb` file so that it includes the mount method call:

```ruby
YourRailsApp::Application.routes.draw do

  # Autoreload the API in development
  if Rails.env.development?
    mount Api.new => '/api'
  end

  #.... rest of routes
end

```

You'll see in the code sample that we're only loading the Restfulness API during development. Our recommendation is to use Restfulness as close to Rack as possible and avoid any of the Rails overhead. To support requests in production, you'll need to update your `/config.rb` so that it looks something like the following:

```ruby
# This file is used by Rack-based servers to start the application.
require ::File.expand_path('../config/environment',  __FILE__)

map = {
  "/" => YourRailsApp::Application
}
unless Rails.env.development?
  map["/api"] = Api.new
end

run Rack::URLMap.new(map)
```

Thats all there is to it! You'll now have auto-reloading in Rails, and fast request handling in production. Just be sure to be careful in development that none of your other Rack middleware interfere with Restfulness. In a new Rails project this certainly won't be an issue.

### The Rack Way

If you're using Restfulness as a standalone project, we recommend using a rack extension like [Shotgun](https://github.com/rtomayko/shotgun) to automatically reload on changes.

## Writing Tests

Test your application by creating requests to your resources and making assertions about the responses.

### RSpec

Configure `rack-test` to be included in your resource specs. One way to does this would be to create a new file `/spec/support/example_groups/restfulness_resource_example_group.rb` with something similar to the following:

```ruby
module RestfulnessResourceExampleGroup
  extend ActiveSupport::Concern
  include Rack::Test::Methods

  # Used by Rack::Test. This could be defined per spec if you have multiple Apps
  def app
    My::Api.new
  end
  protected :app

  # Set the request content type for a JSON payload
  def set_content_type_json
    header('content-type', 'application/json; charset=utf-8')
  end

  # Helper method to POST a json payload
  # post(uri, params = {}, env = {}, &block)
  def post_json(uri, json_data = {}, env = {}, &block)
    set_content_type_json
    post(uri, json_data.to_json, &block)
  end

  included do
    metadata[:type] = :restfulness_resource
  end

  # Setup RSpec to include RestfulnessResourceExampleGroup for all specs in given folder(s)
  RSpec.configure do |config|
    config.include self,
      :type => :restfulness_resource,
      :example_group => { :file_path => %r(spec/resources) }
  end

  # silence logger
  Restfulness.logger = Rack::NullLogger.new(My::Api)
end
```

Make sure in your `spec_helper` all files in the support folder and sub-directories are being loaded. You should have something like the following:

```ruby
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
```

Now you can add a resource spec in the `spec/resources` directory. Here's an example

```ruby
require 'spec_helper'

describe SessionResource do

  let(:user) { create(:user) }

  context 'GET' do
    it 'returns 401 if not authorized' do
      get 'api/session' do |response|
        expect(response.status).to eq 401
      end
    end
  end

  context 'POST' do
    it 'returns 200 when request with correct user info' do
      post_json 'api/session', {:email => user.email, :password => user.password} do |response|
        expect(response.status).to eq 200
      end
    end
  end
end
```

See [Rack::Test](https://github.com/brynary/rack-test) for more information.

A useful gem for making assertions about json objects is [json_spec](https://github.com/collectiveidea/json_spec). This could be included in your `RestfulnessResourceExampleGroup`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write your code and test the socks off it!
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

## Contributors

Restfulness was created by Sam Lown <me@samlown.com> as a solution for building simple APIs at [Cabify](http://www.cabify.com).

The project is now awesome, thanks to contributions by:

 * [Adam Williams](https://github.com/awilliams)
 * [Laura Morillo](https://github.com/lauramorillo)


## Caveats and TODOs

Restfulness is still a work in progress but at Cabify we are using it in production. Here is a list of things that we'd like to improve or fix:

 * Support for more serializers and content types, not just JSON.
 * Support path methods for automatic URL generation.
 * Support redirect exceptions.
 * Needs more functional testing.
 * Support for before and after filters in resources, although I'm slightly apprehensive about this.

## History

### 0.3.4 - August 8, 2016

 * Added helper methods for success responses (@samlown)
 * Don't initialize AuthorizationHeader when authorization is blank. (@arctarus)

### 0.3.3 - January 19, 2016

 * Basic support for handling large request bodies received as Tempfile (@lauramorillo)
 * Providing human readable payload for invalid JSON.
 * Added support for Accept and Content-Type header handling. (@samlown)
 * Better handling of IO objects from `rack.input`, such as `Puma::NullIO`. (@samlown)
 * Upgrading to latest version of RSpec (@samlown)
 * Adding `request.env` accessor to Rack env (@amuino)
 * Removing support for Ruby 1.9 (@samlown)

### 0.3.2 - February 9, 2015

 * Added support for application/x-www-form-urlencoded parameter decoding (@samlown)
 * Support for empty StringIOs when accessing Request#params (@samlown)
 * Fixing at Rack ~> 1.5.0 due to issues with Rack 1.6 (@samlown)

### 0.3.1 - September 19, 2014

 * Added support for HTTP Basic Authentication, no breaking changes. (@samlown)

### 0.3.0 - May 13, 2014

 * Possible breaking change: `put` requests no longer check for existing resource via `exists?` callback. (@samlown)
 * Avoid Rack Lint errors by not providing Content-Type or Length in empty responses. (@samlown)

### 0.2.6 - March 7, 2014

 * Support scope block when adding a resource to router. (@samlown)

### 0.2.5 - March 7, 2014

 * Added support for scope in routes. (@samlown)

### 0.2.4 - February 7, 2014

 * Added I18n support with the help of the http_accept_language gem. (@samlown)

### 0.2.3 - February 6, 2014

 * Fixing issue where query parameters are set as Hash instead of HashWithIndifferentAccess.
 * Rewinding the body, incase rails got there first.
 * Updating the README to describe auto-reloading in Rails projects.
 * Improved handling of Content-Type header that includes encoding. (@awilliams)
 * Return 400 error when malformed JSON is provided in body (@awilliams)
 * Updated documentation to describe resource testing (@awilliams)
 * Now supports filtering of sensitive query and parameter request values (@awilliams)
 * Adding support for X-HTTP-Method-Override header. (@samlown)

### 0.2.2 - October 31, 2013

 * Refactoring logging support to not depend on Rack CommonLogger nor ShowExceptions.
 * Using ActiveSupport::Logger instead of MonoLogger.

### 0.2.1 - October 22, 2013

 * Removing some unnecessary logging and using Rack::CommonLogger.
 * Improving some test coverage. 
 * Supporting user agent in requests.
 * Supporting PATCH method in resources.

### 0.2.0 - October 17, 2013

 * Refactoring error handling and reporting so that it is easier to use and simpler.

### 0.1.0 - October 16, 2013

First release!


