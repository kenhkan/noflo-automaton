_ = require 'lodash'
noflo = require 'noflo'

class WaitFor extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'waitFor'
        ###
        # Wait for a particular element to exist
        #
        # @param {String} selector The CSS selector
        ###
        spooky.then [rule, ->
          @waitForSelector selector
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new WaitFor
