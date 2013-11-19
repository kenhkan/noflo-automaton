_ = require 'lodash'
noflo = require 'noflo'

class Start extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (data) =>
      output = []
      { spooky } = data

      # Capture output from PhantomJS's console
      captureLogs = (log) ->
        regexp = /^\[output\] /
        if (log.space is 'remote') and (log.message.match regexp)
          output.push JSON.parse log.message.replace regexp, ''

      spooky.on 'log', captureLogs

      # Forward packets on completion
      onComplete = _.once =>
        spooky.removeListener 'log', captureLogs

        @outPorts.out.send output
        @outPorts.out.disconnect()

      spooky.on 'run.complete', onComplete
      spooky.on 'exit', onComplete

      # Run the goddamn thing
      spooky.run()

exports.getComponent = -> new Start
