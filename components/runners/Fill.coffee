_ = require 'lodash'
noflo = require 'noflo'

class Fill extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context
      rule = _.clone rule
      rule.form = JSON.stringify rule.form
      rule.submit ?= false

      if rule.action is 'fill'
        spooky.then [rule, ->
          @fill selector, JSON.parse(form), submit
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Fill
