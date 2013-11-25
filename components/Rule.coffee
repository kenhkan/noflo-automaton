noflo = require 'noflo'
_ = require 'lodash'
uuid = require 'uuid'

class Rule extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      action: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      offset = context.offset
      spooky = context.spooky
      rule = _.clone context.rules[offset]

      # Do the action
      @outPorts.action.send
        spooky: spooky
        offset: offset
        rule: rule
        rules: context.rules

      # Forward context object to OUT
      @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      @outPorts.action.disconnect()
      @outPorts.out.disconnect()

exports.getComponent = -> new Rule
