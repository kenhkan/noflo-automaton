noflo = require 'noflo'
Spooky = require 'spooky'
Extract = require '../components/Extract.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testRules = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'extract', selector: '#gbzc #gb_1 .gbts' }
          { action: 'extract', selector: 'input[name="btnG"]', property: 'value' }
          { action: 'extract', selector: 'img', property: 'src' }
        ]
        conditions: [
          { condition: 'Google Search', property: 'value' }
        ]
      }
    ]

    globals.c = Extract.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.outPorts.out.attach globals.out

    globals.setupSpooky = (callback) ->
      options =
        casper:
          clientScripts: [
            './vendor/jquery-2.0.3.min.js'
          ]

      spooky = new Spooky options, ->
        callback spooky

    done()

  'when instantiated':
    'should have an input port': (test) ->
      test.equal typeof globals.c.inPorts.in, 'object'
      test.done()

    'should have an output port': (test) ->
      test.equal typeof globals.c.outPorts.out, 'object'
      test.done()

  'extracting values out of the page':
    'extracts the inner text': (test) ->
      test.expect 2

      actions = globals.testRules[0].actions

      globals.setupSpooky (spooky) ->
        spooky.start 'http://www.google.com'

        # Capture logs
        spooky.on 'log', (log) ->
          # Capture output
          regexp = /^\[output\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = JSON.parse log.message.replace regexp, ''
            test.deepEqual output,
              message: 'values extracted'
              offset: 0
              selector: '#gbzc #gb_1 .gbts'
              property: null
              values: ['Search']

          # Test case completes
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom' and
             log.message.match regexp
            [_regexp, count] = log.message.match regexp
            test.equal count, '3'
            test.done()

        globals.in.send
          spooky: spooky
          action: actions[1]
          offset: 0
        globals.in.disconnect()

        spooky.run()

    'extracts a property value': (test) ->
      test.expect 2

      actions = globals.testRules[0].actions

      globals.setupSpooky (spooky) ->
        spooky.start 'http://www.google.com'

        # Capture logs
        spooky.on 'log', (log) ->
          regexp = /^\[output\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = JSON.parse log.message.replace regexp, ''
            test.deepEqual output,
              message: 'values extracted'
              offset: 0
              selector: 'input[name="btnG"]'
              property: 'value'
              values: ['Google Search']

        # Capture the logs
        spooky.on 'log', (log) ->
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '3'
            test.done()

        globals.in.send
          spooky: spooky
          action: actions[2]
          offset: 0
        globals.in.disconnect()

        spooky.run()

    'extracts multiple values': (test) ->
      test.expect 3

      actions = globals.testRules[0].actions

      globals.setupSpooky (spooky) ->
        spooky.start 'http://www.google.com'

        # Capture logs
        spooky.on 'log', (log) ->
          regexp = /^\[output\] /
          if log.space is 'remote' and
             log.message.match regexp
            output = JSON.parse log.message.replace regexp, ''
            # Should have an array of images
            test.equal output.values.length, 2
            # The rest should match
            delete output.values
            test.deepEqual output,
              message: 'values extracted'
              offset: 0
              selector: 'img'
              property: 'src'

        # Capture the logs
        spooky.on 'log', (log) ->
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '3'
            test.done()

        globals.in.send
          spooky: spooky
          action: actions[3]
          offset: 0
        globals.in.disconnect()

        spooky.run()
