_ = require 'lodash'
noflo = require 'noflo'

class Missing extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky } = context

      params =
        rule: JSON.stringify context.rule
        offset: context.offset

      # Execute in browser space for output
      spooky.then [params, ->
        output = JSON.stringify
          message: 'Unsupported rule'
          offset: offset
          rule: rule
        @log output, 'info', 'output'
        @die "Rule #{rule.action} is not supported", offset
      ]

exports.getComponent = -> new Missing
