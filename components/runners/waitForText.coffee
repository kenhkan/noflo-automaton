_ = require 'lodash'
noflo = require 'noflo'

class WaitForText extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'waitForText'
        ###
        # Wait for a string to appear on screen
        #
        # @param {string} value The string to wait for
        ###
        spooky.then [rule, ->
          @waitForText value
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new WaitForText
