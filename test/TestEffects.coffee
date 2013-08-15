noflo = require 'noflo'
Spooky = require 'spooky'
TestEffects = require '../components/TestEffects.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testRulesSuccess = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="btnk"]' }
        ]
        conditions: [
          { value: 'Google Search', property: 'value' }
        ]
      }
    ]
    globals.testRulesFail = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="notExist"]' }
        ]
        conditions: [
          { value: '', property: 'value' }
        ]
      }
    ]

    globals.c = TestEffects.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()
    globals.retry = noflo.internalSocket.createSocket()
    globals.exit = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.outPorts.out.attach globals.out
    globals.c.outPorts.retry.attach globals.retry
    globals.c.outPorts.exit.attach globals.exit

    done()

  'when instantiated':
    'should have an input port': (test) ->
      test.equal typeof globals.c.inPorts.in, 'object'
      test.done()

    'should have an output port': (test) ->
      test.equal typeof globals.c.outPorts.out, 'object'
      test.equal typeof globals.c.outPorts.retry, 'object'
      test.equal typeof globals.c.outPorts.exit, 'object'
      test.done()

  'test effects of actions':
    'forwards context object and continue the Spooky flow on success': (test) ->
      context =
        rules: globals.testRulesSuccess
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Successful when we get a confirmation from Casper
        spooky.on 'log', (log) ->
          if log.space is 'phantom' and
             log.message.match /^Done [0-9]+ steps in [0-9]+ms/
            test.done()

        # Simulate actions
        spooky.then ->
          @sendKeys 'input[name="q"]', 'Google Search'
        spooky.then ->
          @click 'input[name="btnG"]'

        globals.in.send context
        globals.in.disconnect()

        # Run Spooky
        spooky.run()
