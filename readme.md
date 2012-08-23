[![build status](https://secure.travis-ci.org/outbox/grinder.png)](http://travis-ci.org/outbox/grinder)
# Grinder

Grinder is a simple but powerful router written in [CoffeeScript](http://jashkenas.github.com/coffee-script/)
for [node.js](http://nodejs.org/), inspired by [Sinatra](http://sinatrarb.com/).

## Install

    npm install grinder

## Example

    Router = require('grinder').Router
    http = require('http')

    router = new Router()

    router.get '/hi/@name', () ->
      @response.end("hi #{@name}")

    server = http.createServer (req, res) ->
      router.dispatch({request: req, response: res})

    server.listen(8888)


## API

The router provides methods for assigning new routes and
dispatching new requests.

Each route is assigned to a *verb* and has three main components: a *url pattern*, optional *filters* and a *handler*.

When a new request is dispatched, the router looks for a matching route.
In order to match, a route must be assigned to the request's method
(get, post, etc.), it's url pattern must match the request's url and it
must match every other custom filter provided.

#### Assigning routes

Routers have an `assign` method which receives a *verb*, a *url
pattern*, optional *filters* and a *handler*. This method creates the
route and assignes it to the specified verb.

For example:

    router.assign 'get', '/path', () ->
      ...

For convinience, routers have shortcuts for the following http
verbs: `get`, `post`, `put` and `delete`.

The previous code is equivalent to the following:

    router.get '/path', () ->
      ...

#### Url patterns

You can include variable sections in your url. The matched values will be
passed as arguments to the handler.

You can use `?` to match parameters in the url:

    router.get '/post/?/comment/?', (postId, commentId) ->
      ...

You can also use named parameters, which will be added as properties to
your context object like so:

    router.get '/hello/@name', () ->
      @response.end("hello #{@name}")

You can also use wildcards, which behave like parameters except they can
consume slashes:

    router.get '/a/*/b/*', (a, b) ->
      # on GET /a/1/2/b/3 a = '1/2' and b = '3'
      @response.end("A: #{a} B: #{b}")

#### Request dispatching

Requests are dispatched to the router using the `dispatch` method.

The dispatch method takes a context object which includes a request
or acts like a request. This means that the context object or the
request property of the context object must have the following
properties: *method* and *url*.

When a route matches, the handler is called with `this` set to the
context object.

Example:

    requests = 0
    http.createServer (req, res) ->
      requests++
      router.dispatch({request: req, response: res, number: requests})

    router.get '/', () ->
      @response.end("request number: #{@number}")

#### Filters

You can pass filters to your routes that will be run if the route's url
pattern matches the requested url.

Filters can cancel the matching of a route by returning a false value.

Filters will be called with `this` set to the context object.

Example

    posts = [...]

    findPost = () ->
      @post = posts[@id]

    router.get '/post/@id', findPost, () ->
      # Only executed if the post exists


#### Composing multiple routers

You can delegate certain routes to other routers using the `mount`
method.

Example

    mainRouter = new Router()
    blogRouter = new Router()

    mainRouter.mount '/blog', blogRouter

In this example, every request for a url that starts with /blog will be
handled by the blogRouter.

#### Events

A router emits the following events:

- `new-route` when a new route is created
- `match` when a request matches a route
- `no-match` when the router fails to find a route matching the request

## Testing

Tests are run using [nodeunit](http://github.com/caolan/nodeunit). You
can install nodeunit running:

    npm install -g nodeunit

To run the test suite simply run:

    nodeunit test

## Contributors

- Federico Romero ([federomero](http://github.com/federomero))
- Máximo Martínez ([maxm](http://github.com/maxm))

## License

MIT
