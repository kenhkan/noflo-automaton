noflo = require 'noflo'
testSelector = require '../../common/testSelector'

class Value extends noflo.Component
  actionCount: 2

  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'value'
        ###
        # Put a value into a field by selector
        #
        # @param {String} selector The CSS selector
        # @param {String} value The value to input
        ###
        rule.value ?= ''

        testSelector spooky, rule.selector, context.offset

        spooky.then [rule, ->
          @sendKeys selector, value
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Value
