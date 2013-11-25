noflo = require 'noflo'
testSelector = require '../../common/testSelector'

class Click extends noflo.Component
  actionCount: 2

  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'click'
        ###
        # Click on an element by selector
        #
        # @param {String} selector The CSS selector
        ###
        testSelector spooky, rule.selector, context.offset

        spooky.thenClick rule.selector

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Click
