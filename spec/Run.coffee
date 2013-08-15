noflo = require 'noflo'
Spooky = require 'spooky'
Run = require '../components/Run.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.c = Run.getComponent()
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

  'preconditions':
    'receives a context object': (test) ->
      test.throws ->
        globals.in.send {}
        globals.in.disconnect()
      test.done()

    'receives a Spooky object': (test) ->
      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com/'

        test.doesNotThrow ->
          globals.in.send
            spooky: spooky
          globals.in.disconnect()
        test.done()

        # Run Spooky to avoid memory leak
        spooky.run()

  'send output from phantom browser':
    'forwards an output accumulator wrapped by offset': (test) ->
      test.expect 2

      globals.out.on 'begingroup', (group) ->
        test.equal group, null

      globals.out.on 'data', (data) ->
        test.deepEqual data, []
        test.done()

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com/'

        globals.in.send
          spooky: spooky
        globals.in.disconnect()

        # Run Spooky to avoid memory leak
        spooky.run()

    'output accumulator stores output from phantom browser': (test) ->
      test.expect 2

      globals.out.on 'begingroup', (group) ->
        test.equal group, 8

      globals.out.on 'data', (data) ->
        test.deepEqual data, [
          { some: 'data' }
        ]
        test.done()

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com/'
        spooky.thenEvaluate ->
          console.log JSON.stringify
            some: 'data'

        globals.in.send
          spooky: spooky
          offset: 8
        globals.in.disconnect()

        # Run Spooky to avoid memory leak
        spooky.run()
