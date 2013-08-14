noflo = require 'noflo'

class Run extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (data) =>
      output = []
      { spooky, offset } = data
      offset ?= null

      # Capture output from phantom's console
      spooky.on 'log', (log) ->
        if log.space is 'remote'
          output.push JSON.parse log.message

      # Forward packets on completion
      spooky.on 'run.complete', =>
        @outPorts.out.beginGroup offset
        @outPorts.out.send output
        @outPorts.out.endGroup()
        @outPorts.out.disconnect()

      # Run the goddamn thing
      spooky.run()

exports.getComponent = -> new Run
