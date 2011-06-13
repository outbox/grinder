Router = require('../lib/router').Router
_ = require('underscore')

# Testing basic methods existence

@["Basic constructor"] = (test) ->
  test.doesNotThrow () ->
    new Router()
    test.done()

@["A router should allow to assign simple route"] = (test) ->
  test.doesNotThrow () ->
    router = new Router()
    router.assign 'get', '/test', () ->
    test.done()


for i in ['get', 'post', 'put', 'delete']
  do (i) =>
    @["A router should provide a shortcut function for #{i} requests"] = (test) ->
      router = new Router()
      test.doesNotThrow () ->
        _.isFunction(router[i])
        test.done()

# Test route matching
mockRequest = (url, method = 'get') -> {method: method, url: url}

shouldMatch = (method, url, requestedMethod, requestedUrl, options = {}) =>
  @["Route on '#{method}' with path '#{url}' should match request #{requestedMethod} #{requestedUrl}"] = (test) ->
    router = new Router
    router.assign method, url, () ->
      ok = true
      for own key, value of (options?.params || {})
        ok = ok && this[key] == value.toString()

      for own key, arg of (options?.args || {})
        ok = ok && arguments[key] == arg.toString()

      test.ok(ok)
      test.done()
    router.dispatch(mockRequest(requestedUrl, requestedMethod))

shouldNotMatch = (method, url, requestedMethod, requestedUrl) =>
  @["Route on '#{method}' with path '#{url}' should NOT match request #{requestedMethod} #{requestedUrl}"] = (test) ->
    router = new Router
    router.assign method, url, () ->
    router.on 'no-match', () ->
      test.ok(true)
      test.done()
    router.dispatch(mockRequest(requestedUrl, requestedMethod))

shouldMatch(
  'get', '/hello',
  'get', '/hello'
)
shouldNotMatch(
  'get', '/hello',
  'post', '/hello'
)
shouldMatch(
  'post', '/hello',
  'post', '/hello'
)
shouldMatch(
  'get', '/hello',
  'get', '/hello/'
)
shouldNotMatch(
  'get', '/hello',
  'get', '/hello/wrong'
)

# Test ? params

shouldMatch(
  'get', '/hello/?',
  'get', '/hello/1',
  args: [1]
)
shouldNotMatch(
  'get', '/hello/?',
  'get', '/hello/'
)
shouldNotMatch(
  'get', '/hello/?',
  'get', '/hello/1/2'
)
shouldMatch(
  'get', '/hello/?/bye',
  'get', '/hello/1/bye',
  args: [1]
)
shouldMatch(
  'get', '/hello/?/?',
  'get', '/hello/1/bye',
  args: [1, 'bye']
)
shouldMatch(
  'get', '/hello/?/bye/?',
  'get', '/hello/1/bye/2',
  args: [1, 2]
)
shouldNotMatch(
  'get', '/hello/?/bye/?',
  'get', '/hello/1/bye/'
)

# Test @ params

shouldMatch(
  'get', '/hello/@hi',
  'get', '/hello/1',
  args: [1],
  params: {hi: 1}
)
shouldNotMatch(
  'get', '/hello/@hi',
  'get', '/hello/'
)
shouldNotMatch(
  'get', '/hello/@hi',
  'get', '/hello/1/2'
)
shouldMatch(
  'get', '/hello/@hi/bye',
  'get', '/hello/1/bye',
  args: [1],
  params: {hi: 1}
)
shouldMatch(
  'get', '/hello/@hi/@bye',
  'get', '/hello/1/bye',
  args: [1, 'bye'],
  params: {hi: 1, bye: 'bye'}
)
shouldMatch(
  'get', '/hello/@hi/bye/@bye',
  'get', '/hello/1/bye/2',
  args: [1, 2]
  params: {hi: 1, bye: 2}
)
shouldNotMatch(
  'get', '/hello/?/bye/?',
  'get', '/hello/1/bye/'
)

# Test * params

shouldMatch(
  'get', '/hello/*',
  'get', '/hello/',
}

shouldMatch(
  'get', '/hello/*',
  'get', '/hello/hi',
  args: ['hi']
}

shouldMatch(
  'get', '/hello/*',
  'get', '/hello/hi/there',
  args: ['hi/there']
}

shouldMatch(
  'get', '/hello/*/bye/*',
  'get', '/hello/hi/bye/',
  args: ['hi']
}

shouldMatch(
  'get', '/hello/*/bye/*',
  'get', '/hello/hi/bye/bye',
  args: ['hi', 'bye']
}

shouldMatch(
  'get', '/hello/*/bye/*',
  'get', '/hello/hi/there/bye/bye',
  args: ['hi/there', 'bye']
}


# Test filters


