_ = require 'underscore'
noflo = require 'noflo'
uuid = require 'uuid'

class TestEffects extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      # When successful
      out: new noflo.Port 'object'
      # When failing but hasn't reached retry limit
      retry: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      rule = context.rules[context.offset]
      spooky = context.spooky
      selector = rule.selector

      # Offset should only be incremented once per rule
      incrementOffset = _.once ->
        context.offset++

      # Test each condition
      _.each rule.conditions, (condition) =>
        params = _.clone condition
        params.selector ?= selector

        # Create a unique ID to capture test output
        params.uuid = uuid.v1()

        # Extract the test output as boolean
        captureTestOutput = (log) =>
          regexp = new RegExp "^\\[checkpoint\\] \\[#{params.uuid}\\] "
          if log.space is 'remote' and log.message.match regexp
            # Get rid of listener
            spooky.removeListener 'log', captureTestOutput

            # TODO: implement retry
            # Increment offset if successful as next step will be applied by
            # the next rule. If it fails, retry
            if (log.message.replace regexp, '') is 'true'
              incrementOffset()

        # Place listener with `console` because we log in Casper's environment
        spooky.on 'log', captureTestOutput

        # Add a validation step
        spooky.then [params, ->
          # Wait for the specified selector to apply. Then test the condition.
          @waitForSelector selector, ->
            # Either extract an attribute or the inner HTML
            if property?
              v = @getElementAttribute selector, property
            else
              v = @getHTML selector

            # Report validity checkpoint
            isValid = v is value
            @evaluate (uuid, isValid) ->
              console.log "[checkpoint] [#{uuid}] #{isValid}"
            , uuid, isValid

          , ->
            # Not valid if timed out
            @evaluate (uuid) ->
              console.log "[checkpoint] [#{uuid}] false"
            , uuid
        ]

      # Pass onto the next rule
      @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()

exports.getComponent = -> new TestEffects
