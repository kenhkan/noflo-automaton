_ = require 'lodash'
noflo = require 'noflo'

class Start extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.in.on 'data', (data) =>
      output = []
      completed = false
      { spooky } = data

      # Capture output from PhantomJS's console
      captureLogs = (log) ->
        if (log.space is 'remote') and (log.message.match /^\[output\] /)
          output.push JSON.parse log.message.replace regexp, ''
        if (log.space is 'phantom') and (log.message.match /^Done /)
          completed = true

      spooky.on 'log', captureLogs

      # Forward packets on completion
      onComplete = _.once =>
        spooky.removeListener 'log', captureLogs

        if completed
          @outPorts.out.send output
          @outPorts.out.disconnect()
        else
          @outPorts.error.send output
          @outPorts.error.disconnect()

      spooky.on 'run.complete', onComplete
      spooky.on 'exit', onComplete

      # Run the goddamn thing
      spooky.run()

exports.getComponent = -> new Start
