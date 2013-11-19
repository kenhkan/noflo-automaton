_ = require 'lodash'
noflo = require 'noflo'

class Output extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'output'

        spooky.then [rule, ->
          ## Output for capture
          console.log '[output] ' + JSON.stringify
            message: 'output value'
            offset: offset
            values: value
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Output
