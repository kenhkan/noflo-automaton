noflo = require 'noflo'
testSelector = require '../../common/testSelector'

class JqueryValue extends noflo.Component
  actionCount: 2

  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'jqueryValue'
        ###
        # Change the value of an element by the provided selector
        #
        # @param {String} selector The CSS selector
        # @param {String} value The value to select
        ###
        testSelector spooky, rule.selector, context.offset

        spooky.then [rule, ->
          @evaluate (selector, value) ->
            $(selector).val(value).change()
          , selector, value
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new JqueryValue
