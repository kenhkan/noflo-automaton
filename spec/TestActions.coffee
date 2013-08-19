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

    'outputs and exits unless the element required by the action exists': (test) ->
      test.expect 1

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
            console.log '[success]'

      spooky = new Spooky {}, ->
        context.spooky = spooky
        spooky.start 'http://www.google.com'

        # It should not proceed beyond the action selector test
        spooky.on 'log', (log) ->
          if log.message.match /^\[output\] /
            test.equal log.message, '[output] {"message":"action selector does not exist","offset":0,"selector":"input[name=\\"notExists\\"]"}'
          if log.message is '[success]'
            test.ok false, 'should not have passed the test'

        globals.in.send context
        globals.in.disconnect()

        spooky.on 'exit', ->
          test.done()

        # Run Spooky to avoid memory leak
        spooky.run()
