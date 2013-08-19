_ = require 'underscore'
noflo = require 'noflo'
Setup = require '../components/Setup.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testUrl = 'http://www.google.com'
    globals.testRules = [
      {
        selector: '.foo'
        actions: [
          { action: 'click' }
          { action: 'click', selector: '.bar' }
        ]
        conditions: [
          { value: 'Foo' }
          { value: 'Bar', selector: '.bar' }
        ]
      }
      {
        selector: '.bar'
        actions: [
          { action: 'click' }
        ]
        conditions: [
          { value: 'Bar' }
        ]
      }
    ]

    globals.c = Setup.getComponent()
    globals.url = noflo.internalSocket.createSocket()
    globals.rules = noflo.internalSocket.createSocket()
    globals.options = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()
    globals.error = noflo.internalSocket.createSocket()

    globals.c.inPorts.url.attach globals.url
    globals.c.inPorts.rules.attach globals.rules
    globals.c.inPorts.options.attach globals.options
    globals.c.outPorts.out.attach globals.out
    globals.c.outPorts.error.attach globals.error

    done()

  'when instantiated':
    'should have an input port': (test) ->
      test.equal typeof globals.c.inPorts.url, 'object'
      test.equal typeof globals.c.inPorts.rules, 'object'
      test.equal typeof globals.c.inPorts.options, 'object'
      test.done()

    'should have an output port': (test) ->
      test.equal typeof globals.c.outPorts.out, 'object'
      test.equal typeof globals.c.outPorts.error, 'object'
      test.done()

  'preconditions':
    'rule object is an array': (test) ->
      globals.error.on 'data', (data) ->
        test.equal data.message, 'Rule object must be an array'
        test.done()

      globals.url.send globals.testUrl
      globals.rules.send {}
      globals.url.disconnect()
      globals.rules.disconnect()

    'rule object must contain at least one rule': (test) ->
      globals.error.on 'data', (data) ->
        test.equal data.message, 'Empty rule object'
        test.done()

      globals.url.send globals.testUrl
      globals.rules.send []
      globals.url.disconnect()
      globals.rules.disconnect()

    'rule object has a selector, actions, and conditions': (test) ->
      globals.error.on 'data', (data) ->
        test.equal data.message, 'Rule object must contain a selector, actions, and conditions'
        test.done()

      globals.url.send globals.testUrl
      globals.rules.send [
        selector: '.foo'
      ]
      globals.url.disconnect()
      globals.rules.disconnect()

    'actions in rule object must have an action property': (test) ->
      globals.error.on 'data', (data) ->
        test.equal data.message, 'Rule object actions must contain an action property'
        test.done()

      globals.url.send globals.testUrl
      globals.rules.send [
        selector: '.foo'
        actions: [
          {}
        ]
        conditions: [
          { value: 'Foo' }
        ]
      ]
      globals.url.disconnect()
      globals.rules.disconnect()

    'conditions in rule object must have a value property': (test) ->
      globals.error.on 'data', (data) ->
        test.equal data.message, 'Rule object conditions must contain a value property'
        test.done()

      globals.url.send globals.testUrl
      globals.rules.send [
        selector: '.foo'
        actions: [
          { action: 'click' }
        ]
        conditions: [
          {}
        ]
      ]
      globals.url.disconnect()
      globals.rules.disconnect()

    'receives a valid options object': (test) ->
      globals.error.on 'data', (data) ->
        test.equal data.message, 'Options object is not valid'
        test.done()

      globals.url.send globals.testUrl
      globals.rules.send [
        selector: ''
        actions: [{ action: '' }]
        conditions: [{ condition: '' }]
      ]
      globals.options.send false
      globals.url.disconnect()
      globals.rules.disconnect()
      globals.options.disconnect()

  'SpookyJS setup':
    'starts with the provided URL and options': (test) ->
      globals.out.on 'data', (data) ->
        test.ok _.isFunction data.spooky.then
        test.ok _.isFunction data.spooky.thenEvaluate
        test.ok _.isArray data.rules
        test.ok _.isObject data.counts

        # Run Spooky to avoid memory leak
        data.spooky.run()
        test.done()

      globals.url.send globals.testUrl
      globals.rules.send globals.testRules
      globals.options.send
        verbose: true
      globals.url.disconnect()
      globals.rules.disconnect()
      globals.options.disconnect()

    'starts with the provided URL but no options': (test) ->
      globals.out.on 'data', (data) ->
        test.ok _.isFunction data.spooky.then
        test.ok _.isFunction data.spooky.thenEvaluate
        test.ok _.isArray data.rules
        test.ok _.isObject data.counts

        # Run Spooky to avoid memory leak
        data.spooky.run()
        test.done()

      globals.url.send globals.testUrl
      globals.rules.send globals.testRules
      globals.url.disconnect()
      globals.rules.disconnect()

    'automatically injects jQuery': (test) ->
      globals.out.on 'data', (data) ->
        data.spooky.on 'log', (log) ->
          regexp = /^\[output\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = log.message.replace regexp, ''
            test.done() if output is 'true'

        data.spooky.then ->
          @evaluate ->
            console.log "[output] #{window.jQuery?}"

        # Run Spooky to avoid memory leak
        data.spooky.run()

      globals.url.send globals.testUrl
      globals.rules.send globals.testRules
      globals.url.disconnect()
      globals.rules.disconnect()
