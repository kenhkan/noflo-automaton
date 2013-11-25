_ = require 'lodash'
noflo = require 'noflo'

class Wait extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'wait'
        ###
        # Wait for some time (in milliseconds)
        #
        # @param {Number} timeout The period in milliseconds
        ###
        rule.timeout ?= 3000

        spooky.then [rule, ->
          @wait timeout
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Wait
