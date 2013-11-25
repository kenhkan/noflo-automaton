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
        ###
        # Print stuff to screen
        #
        # @param {String} value The message to print to screen
        ###
        spooky.then [rule, ->
          # Output for capture
          output = JSON.stringify
            message: 'Output value'
            offset: offset
            values: value

          @log output, 'info', 'output'
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Output
