noflo = require 'noflo'

class Iterate extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.ArrayPort 'object'
    @outPorts =
      out: new noflo.Port 'object'
      ready: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      # Increment offset if it exists; otherwise start at 0
      if context.offset?
        context.offset++
      else
        context.offset = 0

      # Send to OUT if there are still rules left; to READY otherwise
      if context.rules[context.offset]?
        @outPorts.out.send context
      else
        context.offset = null
        @outPorts.ready.send context

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()
      @outPorts.ready.disconnect()

exports.getComponent = -> new Iterate
