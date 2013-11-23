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

      # Capture output from CasperJS/PhantomJS
      captureLogs = (log) ->
        if (log.space is 'remote') and (log.message.match /^\[output\] /)
          output.push JSON.parse log.message.replace regexp, ''

      spooky.on 'log', captureLogs

      # Forward packets on completion
      onComplete = _.once =>
        spooky.removeListener 'log', captureLogs
        @outPorts.out.send output
        @outPorts.out.disconnect()

      spooky.on 'run.complete', onComplete

      # Forward packets also on error
      onError = _.once =>
        spooky.removeListener 'log', captureLogs
        @outPorts.error.send output
        @outPorts.error.disconnect()

      spooky.on 'die', onError

      # Run the goddamn thing
      spooky.run()

exports.getComponent = -> new Start
