noflo = require 'noflo'

class Iterate extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.ArrayPort 'object'
    @outPorts =
      out: new noflo.Port 'object'
      exit: new noflo.Port 'object'

    @inPorts.in.on 'data', (data) =>
      # Increment offset if it exists; otherwise start at 0
      if data.offset?
        data.offset++
      else
        data.offset = 0

      # Send to OUT if there are still rules left; to exit otherwise
      if data.rules[data.offset]?
        @outPorts.out.send data
      else
        data.offset = null
        @outPorts.exit.send data

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()
      @outPorts.exit.disconnect()

exports.getComponent = -> new Iterate
