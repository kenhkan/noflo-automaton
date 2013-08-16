noflo = require 'noflo'
Spooky = require 'spooky'
Click = require '../components/Click.coffee'

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

    globals.c = Click.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.outPorts.out.attach globals.out

    done()

  'when instantiated':
    'should have an input port': (test) ->
      test.equal typeof globals.c.inPorts.in, 'object'
      test.done()

  'clicking on an element':
    'ignores and forwards if the action is not a "click"': (test) ->
      test.expect 2

      actions = globals.testRules[0].actions

      globals.out.on 'data', (context) ->
        test.equal context.action, actions[0]

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '2'
            test.done()

        # This is ignored
        globals.in.send
          spooky: spooky
          action: actions[0]
        globals.in.disconnect()

        spooky.run()

    'does not forward if OUT is not attached': (test) ->
      test.expect 1
      globals.c.outPorts.out.detach()

      actions = globals.testRules[0].actions

      globals.out.on 'data', (context) ->
        test.ok false, 'should not receive anything if detached'

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '2'
            test.done()

        # This is ignored
        globals.in.send
          spooky: spooky
          action: actions[0]
        globals.in.disconnect()

        spooky.run()

    'click if it is a "click"': (test) ->
      test.expect 1

      actions = globals.testRules[0].actions

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '3'
            test.done()

        # This is executed
        globals.in.send
          spooky: spooky
          action: actions[1]
        globals.in.disconnect()

        spooky.run()
