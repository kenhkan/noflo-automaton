noflo = require 'noflo'
Spooky = require 'spooky'
Missing = require '../components/Missing.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testRules = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { condition: '', property: 'value' }
        ]
      }
    ]

    globals.c = Missing.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.outPorts.out.attach globals.out

    done()

  'when instantiated':
    'should have an input port': (test) ->
      test.equal typeof globals.c.inPorts.in, 'object'
      test.done()

    'should have an output port': (test) ->
      test.equal typeof globals.c.outPorts.out, 'object'
      test.done()

  'clicking on an element':
    'always output "action runner missing"': (test) ->
      test.expect 2

      actions = globals.testRules[0].actions
      action = actions[0]

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          # Capture output
          regexp = /^\[output\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = JSON.parse log.message.replace regexp, ''
            test.equal output.message, 'action runner missing'

          # Time to finish
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom' and
             log.message.match regexp
            [_regexp, count] = log.message.match regexp
            test.equal count, '3'
            test.done()

        # This is executed
        globals.in.send
          spooky: spooky
          action: action
          offset: 0
        globals.in.disconnect()

        spooky.run()
