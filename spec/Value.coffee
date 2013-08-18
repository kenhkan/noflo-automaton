noflo = require 'noflo'
Spooky = require 'spooky'
Value = require '../components/Value.coffee'

globals = {}

module.exports =
  setUp: (done) ->
    globals.testRules = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'click' }
          { action: 'value', value: 'Searching', selector: 'input[name="q"]' }
        ]
        conditions: [
          { condition: 'Google Search', property: 'value' }
        ]
      }
    ]

    globals.c = Value.getComponent()
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

  'typing a value into a field':
    'ignores and forwards if the action is not a "click"': (test) ->
      test.expect 2

      actions = globals.testRules[0].actions

      globals.out.on 'data', (context) ->
        test.equal context.action, actions[0]

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '2'
            test.done()

        # This is ignored
        globals.in.send
          spooky: spooky
          action: actions[0]
        globals.in.disconnect()

        spooky.run()

    'does not forward if OUT is not attached': (test) ->
      test.expect 1
      globals.c.outPorts.out.detach()

      actions = globals.testRules[0].actions

      globals.out.on 'data', (context) ->
        test.ok false, 'should not receive anything if detached'

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'log', (log) ->
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.equal count, '2'
            test.done()

        # This is ignored
        globals.in.send
          spooky: spooky
          action: actions[0]
        globals.in.disconnect()

        spooky.run()

    'types the value': (test) ->
      test.expect 2

      actions = globals.testRules[0].actions
      action = actions[1]

      spooky = new Spooky {}, ->
        spooky.start 'http://www.google.com'

        # Capture the logs
        spooky.on 'console', (log) ->
          # Test value shouldn't have been updated
          regexp = /\[test-value\] (.*)/
          if log.match regexp
            [_log, match] = log.match regexp
            test.equal match, ''

          # Value should have been set
          regexp = /\[valid\] (.+)/
          if log.match regexp
            [_log, match] = log.match regexp
            switch match
              when 'true'
                test.ok true
              when 'false'
                test.ok false, 'value not set'

        spooky.on 'log', (log) ->
          regexp = /^Done ([0-9]+) steps in/
          if log.space is 'phantom'
            [_regexp, count] = log.message.match regexp
            test.done()

        # This is executed
        globals.in.send
          spooky: spooky
          action: action
        globals.in.disconnect()

        # The field should not *reflect* that it contains the text even though
        # it does (due to a pecularity in Casper.js
        spooky.then [action, ->
          value = @getElementAttribute selector, 'value'
          console.log "[test-value] #{value}"
        ]

        # Click on submit button and we should see the value was indeed there
        spooky.then ->
          @click 'form[name="f"] [type="submit"]'
        spooky.waitFor [action, ->
          @getElementAttribute('input[name="q"]', 'value') is value
        ], ->
          console.log '[valid] true'
        , ->
          console.log '[valid] false'

        spooky.run()
