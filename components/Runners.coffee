noflo = require 'noflo'
_ = require 'lodash'
uuid = require 'uuid'

class Runners extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      action: new noflo.ArrayPort 'object'

    @inPorts.in.on 'data', (context) =>
      offset = context.offset
      spooky = context.spooky
      rule = context.rules[offset]

      # Do the action
      @outPorts.action.send
        spooky: spooky
        offset: offset
        rule: rule

      # Offset is incremented once per rule
      context.offset++

      # Forward context object to OUT
      @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      @outPorts.action.disconnect()
      @outPorts.out.disconnect()

exports.getComponent = -> new Runners
