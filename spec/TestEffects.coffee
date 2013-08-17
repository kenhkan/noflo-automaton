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
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Google Search', property: 'value', selector: 'form input[type="text"]' }
          { value: 'Search', selector: 'div#ab_name span' }
        ]
      }
    ]
    globals.testRulesFail = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Not this search', property: 'value', selector: 'form input[type="text"]' }
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
    'forwards context object on success': (test) ->
      test.expect 1

      context =
        rules: globals.testRulesSuccess
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      globals.exit.on 'data', (data) ->
        test.ok false, 'should not exit because the selector and value match'

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

    'increments the offset when *running* on success': (test) ->
      test.expect 2

      context =
        rules: globals.testRulesSuccess
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      globals.exit.on 'data', (data) ->
        test.ok false, 'should not exit because the selector and value match'

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Capture logging from other environments
        spooky.on 'log', (log) ->
          # Test offset
          if log.space is 'remote' and
             log.message is '[offset]'
            test.equal context.offset, 1

          # Finish on success
          if log.space is 'phantom' and
             log.message.match /^Done [0-9]+ steps in [0-9]+ms/
            test.done()

        # Simulate actions
        spooky.then ->
          @sendKeys 'input[name="q"]', 'Google Search'
        spooky.then ->
          @click 'input[name="btnG"]'

        # Set the tester
        globals.in.send context
        globals.in.disconnect()

        # Set offset capture flag
        spooky.thenEvaluate ->
          console.log '[offset]'

        # Run Spooky
        spooky.run()

    'forwards context object but sends to EXIT on failure': (test) ->
      test.expect 3

      context =
        rules: globals.testRulesFail
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      globals.exit.on 'data', (data) ->
        test.deepEqual data, context
        test.equal data.offset, 0

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          regexp = /^Step 7\/7: done/
          if log.space is 'phantom' and
             log.message.match regexp
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
