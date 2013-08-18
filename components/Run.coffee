noflo = require 'noflo'

class Run extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.ArrayPort 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (data) =>
      output = []
      { spooky, offset, rules } = data

      # Set the offset to `null` (i.e. successful exit) if it has reached the
      # end of the rules
      offset = null if not offset? or offset >= rules.length

      # Capture output from phantom's console
      captureLogs = (log) ->
        regexp = /^\[output\] /
        if (log.space is 'remote') and (log.message.match regexp)
          output.push JSON.parse log.message.replace regexp, ''

      spooky.on 'log', captureLogs

      # Forward packets on completion
      onComplete = =>
        spooky.removeListener 'log', captureLogs

        @outPorts.out.beginGroup offset
        @outPorts.out.send output
        @outPorts.out.endGroup()
        @outPorts.out.disconnect()

      spooky.on 'run.complete', onComplete
      spooky.on 'exit', onComplete

      # Run the goddamn thing
      spooky.run()

exports.getComponent = -> new Run
