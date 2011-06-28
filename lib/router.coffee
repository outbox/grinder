_ = require('underscore')
EventEmitter = require('events').EventEmitter

class Route
  constructor: (@matcher, @filters, @handler) ->
    if _.isFunction(matcher)
      @matcher = matcher
    else if _.isString(matcher)
      @matcher = matcherFromString(matcher)
    else if _.isRegExp(matcher)
      @matcher = matcherFromRegExp(matcher)

  match: (pathname, context) ->
    match = @matcher(pathname)
    if match
      # extend context with matched params
      for own [param, value] in  match
        if param[0] == '@'
          context[param.substr(1)] = value

      if @runFilters(context, match)
        match

  runFilters: (context, match) ->
    for filter in @filters
      result = filter.apply(context, match.map((m) -> m[1]))
      return false if !result

    return true

matcherFromRegExp = (r) ->
  (url) ->
    r.exec(url)?.slice(1)

buildRegexp = (s) ->
  keys = []

  # Escape dots
  s = s.replace '.', '\\.'

  # Replacing *@key* and *:key* patterns with regexp groups
  s = s.replace /(@\w+|\?)/g, (match) ->
    keys.push(match)
    '([^/?#]+)'

  # And *\** with non greedy .*
  s = s.replace /\*/g, (match) ->
    keys.push(match)
    '(.*?)'

  regexp = new RegExp('^'+s+'/?$')
  return [regexp, keys]

matcherFromString = (s) ->
  [regexp, keys] = buildRegexp(s)

  (path) ->
    params = regexp.exec(path)?.slice(1)
    if params
      _.zip(keys, params)

getMethod = (context) ->
  (context.method || 'get').toLowerCase()

getPathname = (context) ->
  url = context.url || context.request?.url || '/'
  url = require('url').parse(url) if _.isString(url)
  url.pathname

class Router extends EventEmitter
  constructor: () ->
    @routes = {}
    @mountedRouters = {}

  dispatch: (context, prefix = '') ->
    method = getMethod(context)
    pathname = getPathname(context)

    if prefix.length > 0 && pathname.indexOf(prefix) == 0
      pathname = pathname.substr(prefix.length)

    for path, route of @mountedRouters
      if pathname.indexOf(path) == 0
        return route.dispatch(context, prefix.concat(path))

    for own route in (@routes[method] || [])
      newContext = _.clone(context)
      match = route.match(pathname, newContext)
      if match
        @emit('match', newContext, route, pathname)
        @handleMatch(newContext, route, match)
        break

    @emit('no-match', context) unless match

  handleMatch: (context, route, match) ->
    route.handler.apply(context, match.map((p) -> p[1]))

  assign: (method, path, filters..., handler) ->
    method = method.toLowerCase()
    route = new Route(path, filters, handler)
    @routes[method] ||= []
    @routes[method].push(route)
    @emit('new-route', method, route, filters, handler)
    return @

  mount: (path, router) ->
    router.on 'match', () =>
      @emit.apply('match', arguments)

    router.on 'no-match', () =>
      @emit.apply('no-match', arguments)

    @mountedRouters[path] = router


for verb in ['get', 'post', 'put', 'delete']
  do (verb) ->
    Router::[verb] = (args...) ->
      this.assign.apply(this, [verb].concat(args))

exports.Router = Router
