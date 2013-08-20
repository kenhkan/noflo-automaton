noflo = require 'noflo'
Spooky = require 'spooky'
TestActions = require '../components/TestActions.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testRules = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="notExists"]' }
        ]
        conditions: [
          { condition: 'Google Search', property: 'value' }
        ]
      }
    ]

    globals.c = TestActions.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()
    globals.action = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.outPorts.out.attach globals.out
    globals.c.outPorts.action.attach globals.action

    done()

  'when instantiated':
    'should have an input port': (test) ->
      test.equal typeof globals.c.inPorts.in, 'object'
      test.done()

    'should have an output port': (test) ->
      test.equal typeof globals.c.outPorts.out, 'object'
      test.equal typeof globals.c.outPorts.action, 'object'
      test.done()

  'action switching':
    'passes the context object with the number of actions to OUT and rules wrapped in the action name to ACTION': (test) ->
      test.expect 3

      rule = globals.testRules[0]
      expectedActionData = for action in rule.actions
        action.selector ?= rule.selector
        action

      context =
        rules: globals.testRules
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.equal data.counts.actions, 2

      globals.action.on 'data', (data) ->
        context =
          spooky: spooky
          action: expectedActionData.shift()
          offset: 0
        test.deepEqual data, context

      globals.out.on 'disconnect', ->
        test.done()

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'http://www.google.com'

        globals.in.send context
        globals.in.disconnect()

        # Run Spooky to avoid memory leak
        spooky.run()

    'outputs and skips one (i.e. the action) if the element required by the action does not exist': (test) ->
      test.expect 2

      # Remove the first action to test only the failing action
      globals.testRules[0].actions.shift()
      rule = globals.testRules[0]
      context =
        rules: globals.testRules
        offset: 0
        counts:
          actions: 0

      globals.action.on 'data', (data) ->
        data.spooky.then ->
          @evaluate ->
            # Hack: see TestActions on `bypass()`
            if window._bypass is 0
              console.log '[skipped]'
        data.spooky.then ->
          @evaluate ->
            # Hack: see TestActions on `bypass()`
            if window._bypass > 0
              console.log '[not-skipped]'

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'http://www.google.com'

        # It should not proceed beyond the action selector test
        spooky.on 'log', (log) ->
          if log.message.match /^\[output\] /
            test.equal log.message, '[output] {"message":"action selector does not exist","offset":0,"selector":"input[name=\\"notExists\\"]"}'
          if log.message is '[skipped]'
            test.ok false, 'the next step should have been skipped'
          if log.message is '[not-skipped]'
            test.ok true

        globals.in.send context
        globals.in.disconnect()

        spooky.on 'run.complete', ->
          test.done()

        # Run Spooky to avoid memory leak
        spooky.run()
