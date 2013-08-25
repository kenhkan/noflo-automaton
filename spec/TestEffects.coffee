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
    globals.testRulesSuccessWithoutValue = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Google Search', property: 'value', selector: 'form input[type="text"]' }
          { selector: 'div#ab_name span' }
        ]
      }
    ]
    globals.testRulesFailNoSelector = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Not this search', property: 'value', selector: '#does-not-exist' }
        ]
      }
    ]
    globals.testRulesFailInvalidCondition = [
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
    globals.testRulesSkipOnFailure = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
        ]
        conditions: [
          {
            value: 'Not this search'
            property: 'value'
            onFailure: 'retained'
          }
        ]
      }
      {
        name: 'skipped'
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'This is skipped' }
        ]
        conditions: [
          {
            value: 'This is skipped'
          }
        ]
      }
      {
        name: 'retained'
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'This is retained' }
        ]
        conditions: [
          {
            value: 'This is NOT retained'
          }
        ]
      }
    ]
    globals.testRulesSkipOnTimeoutFailure = [
      {
        selector: 'div.does-not-exist'
        actions: [
          { action: 'value', value: 'Google Search' }
        ]
        conditions: [
          {
            value: 'Not this search'
            property: 'value'
            onFailure: 'retained'
          }
        ]
      }
      {
        name: 'skipped'
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'This is skipped' }
        ]
        conditions: [
          {
            value: 'This is skipped'
          }
        ]
      }
      {
        name: 'retained'
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'This is retained' }
        ]
        conditions: [
          {
            value: 'This is NOT retained'
          }
        ]
      }
    ]

    globals.c = TestEffects.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()
    globals.retry = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.outPorts.out.attach globals.out
    globals.c.outPorts.retry.attach globals.retry

    done()

  'when instantiated':
    'should have an input port': (test) ->
      test.equal typeof globals.c.inPorts.in, 'object'
      test.done()

    'should have an output port': (test) ->
      test.equal typeof globals.c.outPorts.out, 'object'
      test.equal typeof globals.c.outPorts.retry, 'object'
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

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Successful when we get a confirmation from Casper
        spooky.on 'log', (log) ->
          # Should not fail
          if log.space is 'remote' and
             log.message.match /^\[checkpoint\] .+ false$/
            test.ok false, 'should not fail'

          # Finish
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

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Capture logging from other environments
        spooky.on 'log', (log) ->
          # Should not fail
          if log.space is 'remote' and
             log.message.match /^\[checkpoint\] .+ false$/
            test.ok false, 'should not fail'

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

    'tests for existence if no value is provided': (test) ->
      test.expect 2

      context =
        rules: globals.testRulesSuccessWithoutValue
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Capture the logs
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

        globals.in.send context
        globals.in.disconnect()

        # Set offset capture flag
        spooky.thenEvaluate ->
          console.log '[offset]'

        # Run Spooky
        spooky.run()

  'failing cases':
    'the condition selector does not exist': (test) ->
      test.expect 2

      context =
        rules: globals.testRulesFailNoSelector
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          # Capture output
          regexp = /^\[output\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = JSON.parse log.message.replace regexp, ''
            test.equal output.message, 'condition selector does not exist'
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

    'the condition is invalid': (test) ->
      test.expect 2

      context =
        rules: globals.testRulesFailInvalidCondition
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          # Capture output
          regexp = /^\[output\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = JSON.parse log.message.replace regexp, ''
            test.equal output.message, 'condition invalid'
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

  'on failure':
    'find the next offset starting from the current offset by name': (test) ->
      testEffects = TestEffects.getComponent()
      rules = globals.testRulesSkipOnFailure
      nextOffset = testEffects.findNext rules, 0, 'retained'

      test.equal nextOffset, 2
      test.done()

    'returns null if next offset isnt found': (test) ->
      testEffects = TestEffects.getComponent()
      rules = globals.testRulesSkipOnFailure
      nextOffset = testEffects.findNext rules, 0, 'not-exist'

      test.equal nextOffset, null
      test.done()

    'skipping to a certain rule by name': (test) ->
      test.expect 2

      context =
        rules: globals.testRulesSkipOnFailure
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          # Capture output
          regexp = /^\[output\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = JSON.parse log.message.replace regexp, ''
            test.equal output, 2
            test.done()

        globals.in.send context
        globals.in.disconnect()

        # Bypass in browser
        spooky.then ->
          @evaluate ->
            console.log "[output] #{window._bypass}"

        # Run Spooky
        spooky.run()

    'skipping to a certain rule by name when timed out': (test) ->
      test.expect 2

      context =
        rules: globals.testRulesSkipOnTimeoutFailure
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.deepEqual data, context

      spooky = new Spooky { casper: { verbose: true } }, ->
        context.spooky = spooky
        spooky.start 'https://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          # Capture output
          regexp = /^\[test\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = JSON.parse log.message.replace regexp, ''
            test.equal output, 2
            test.done()

        globals.in.send context
        globals.in.disconnect()

        # Bypass in browser
        spooky.then ->
          @evaluate ->
            console.log "[test] #{window._bypass}"

        # Run Spooky
        spooky.run()
