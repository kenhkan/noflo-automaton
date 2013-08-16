noflo = require 'noflo'
Spooky = require 'spooky'
Fill = require '../components/Fill.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testRules = [
      {
        selector: 'form[name="f"]'
        actions: [
          {
            action: 'fill'
            selector: 'form[name="f"]'
            form:
              q: 'Search Terms'
            submit: true
          }
          {
            action: 'fill'
            selector: 'form[name="f"]'
            form:
              q: 'Search Terms'
          }
        ]
        conditions: [
          { condition: 'Search Terms', property: 'value' }
        ]
      }
    ]

    globals.c = Fill.getComponent()
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

  'filling a form':
    'fills a form and submits it': (test) ->
      test.expect 2

      actions = globals.testRules[0].actions

      globals.out.on 'data', (context) ->
        test.equal context.action, actions[0]

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          # We're on the search page
          regexp = /^url changed to "http:.+q\=Search\+Terms/
          if log.space is 'phantom' and
             log.message.match regexp
            test.ok true, 'form submitted'

          # Complete on done
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '3'
            test.done()

        # Fill form and submit
        globals.in.send
          spooky: spooky
          action: actions[0]
        globals.in.disconnect()

        spooky.run()

    'fills a form without submitting': (test) ->
      test.expect 1

      actions = globals.testRules[0].actions

      globals.out.on 'data', (context) ->
        test.equal context.action, actions[0]

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          # We're on the search page
          regexp = /^url changed to "http:.+q\=Search\+Terms/
          if log.space is 'phantom' and
             log.message.match regexp
            test.ok false, 'form should not have been submitted'

          # Complete on done
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '3'
            test.done()

        # Fill form only
        globals.in.send
          spooky: spooky
          action: actions[1]
        globals.in.disconnect()

        spooky.run()
