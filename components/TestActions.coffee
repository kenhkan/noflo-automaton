noflo = require 'noflo'
_ = require 'underscore'
uuid = require 'uuid'

class TestActions extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.ArrayPort 'object'
    @outPorts =
      out: new noflo.Port 'object'
      action: new noflo.ArrayPort 'object'
      exit: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      rule = context.rules[context.offset]
      spooky = context.spooky

      # Go through each action and send as individual packet
      _.each rule.actions, (origAction) =>
        action = _.clone origAction
        # Use rule's selector by default
        action.selector ?= rule.selector

        # Create a unique ID to capture test output
        action.uuid = uuid.v1()

        # Extract the test output as boolean
        captureTestOutput = (log) =>
          regexp = new RegExp "^\\[checkpoint\\] \\[#{action.uuid}\\] "
          if log.match regexp
            # Exit on failure
            if (log.replace regexp, '') is 'false'
              @outPorts.exit.send context
              @outPorts.exit.disconnect()

            # Get rid of listener
            spooky.removeListener 'console', captureTestOutput

        # Place listener with `console` because we log in Casper's environment
        spooky.on 'console', captureTestOutput

        # Test the selector
        spooky.then [action, ->
          # Don't do anything if it passes as it implicitly moves to the next
          # step, but exit on failure
          @waitForSelector selector, (->), ->
            console.log "[checkpoint] [#{uuid}] false"
        ]

        # Do the action
        @outPorts.action.send
          spooky: spooky
          action: origAction

      # THEN, set the number of actions and forward context object to OUT
      context.counts.actions = rule.actions.length
      @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      @outPorts.action.disconnect()
      @outPorts.out.disconnect()

exports.getComponent = -> new TestActions