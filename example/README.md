
# Restfulness Example App

Really simple example of a basic app with a couple of resources.

## Preparation

Use bundler to make sure all the dependencies are in place:

    cd example
    bundle install

By default, bundler will expect to find the restfulness gem provided in the parent directory.

## Running

    bundle exec runit

## Testing

Curl is your friend!

    # Get nothing (returns 404)
    curl -v http://localhost:9292/projects

    # Post a journey
    curl -v -X POST http://localhost:9292/project -H "Content-Type: application/json" -d "{\"id\":\"project1\",\"name\":\"First Project\"}"

    # Retrieve it
    curl -v http://localhost:9292/project/project1

    # Get an array of projects
    curl -v http://localhost:9292/projects
    
    # Try updating it
    curl -v -X PUT http://localhost:9292/project/project1 -H "Content-Type: application/json" -d "{\"name\":\"First Updated Project\"}"

    # Finally remove it and check the list is empty
    curl -v -X DELETE http://localhost:9292/project/project1
    curl -v http://localhost:9292/projects


