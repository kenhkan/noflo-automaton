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
        # @param {number=} timeout Number of milliseconds to wait for. Default
        #   to 5 seconds
        ###
        rule.timeout ?= 5000
        rule.step = context.offset

        spooky.then [rule, ->
          @waitForText value, (->), =>
            @die "#{value} is not found on page after #{timeout} milliseconds", step
          , timeout
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new WaitForText
