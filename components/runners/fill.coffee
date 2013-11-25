_ = require 'lodash'
noflo = require 'noflo'
testSelector = require '../../common/testSelector'

class Fill extends noflo.Component
  actionCount: 2

  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'fill'
        ###
        # Fill out a form
        #
        # @param {String} selector The CSS selector
        # @param {Object} form The form in the format of name-value map
        # @param {Boolean=} submit Fill and submit the form
        ###
        rule.form = JSON.stringify rule.form or {}
        rule.submit ?= false

        testSelector spooky, rule.selector, context.offset

        spooky.then [rule, ->
          @fill selector, JSON.parse(form), submit
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Fill
