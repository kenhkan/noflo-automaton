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
        @evaluate (rule, offset) ->
          console.log '[output] ' + JSON.stringify
            message: 'rule runner missing'
            offset: offset
            rule: rule
        , (JSON.parse rule), offset
      ]

exports.getComponent = -> new Missing
