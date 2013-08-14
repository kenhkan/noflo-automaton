noflo = require 'noflo'
Spooky = require 'spooky'
Iterate = require '../components/Iterate.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testRules = [
      {
        selector: '.foo'
        actions: [
          { action: 'click' }
          { action: 'click', selector: '.bar' }
        ]
        conditions: [
          { condition: 'Foo' }
          { condition: 'Bar', selector: '.bar' }
        ]
      }
      {
        selector: '.bar'
        actions: [
          { action: 'click' }
        ]
        conditions: [
          { condition: 'Bar' }
        ]
      }
    ]

    globals.c = Iterate.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()
    globals.exit = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.outPorts.out.attach globals.out
    globals.c.outPorts.exit.attach globals.exit

    done()

  'when instantiated':
    'should have an input port': (test) ->
      test.equal typeof globals.c.inPorts.in, 'object'
      test.done()

    'should have an output port': (test) ->
      test.equal typeof globals.c.outPorts.out, 'object'
      test.equal typeof globals.c.outPorts.exit, 'object'
      test.done()

  'iterating through the loop':
    'creates `offset` if it does not exist': (test) ->
      globals.out.on 'data', (data) ->
        test.equal data.offset, 0
        test.done()

      globals.in.send
        rules: globals.testRules
      globals.in.disconnect()

    'increments `offset` if specified rule exists': (test) ->
      globals.out.on 'data', (data) ->
        test.equal data.offset, 1
        test.done()

      globals.in.send
        rules: globals.testRules
        offset: 0
      globals.in.disconnect()

    'exits successfully if rule does not exist': (test) ->
      globals.exit.on 'data', (data) ->
        test.equal data.offset, null
        test.done()

      globals.in.send
        rules: globals.testRules
        offset: 2
      globals.in.disconnect()
