noflo = require 'noflo'
Spooky = require 'spooky'
SwitchActions = require '../components/SwitchActions.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testRules = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="btnk"]' }
        ]
        conditions: [
          { condition: 'Google Search', property: 'value' }
        ]
      }
    ]

    globals.c = SwitchActions.getComponent()
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

      # Use failing rules as successful rules jump to another page
      context =
        rules: globals.testRules
        offset: 0
        counts:
          actions: 0

      globals.out.on 'data', (data) ->
        test.equal data.counts.actions, 2

      globals.action.on 'data', (data) ->
        test.deepEqual data, expectedActionData.shift()

      globals.out.on 'disconnect', ->
        test.done()

      spooky = new Spooky {}, ->
        context.spooky = spooky

        globals.in.send context
        globals.in.disconnect()

        # Run Spooky to avoid memory leak
        process.nextTick -> spooky.run()
