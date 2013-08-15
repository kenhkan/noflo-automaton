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
      # When failing and has retried
      exit: new noflo.Port 'object'

    @inPorts.in.on 'data', (data) =>
      rule = data.rules[data.offset]
      spooky = data.spooky
      selector = rule.selector

      # Test each condition
      _.each rule.conditions, (condition) =>
        params = _.clone condition
        params.selector ?= selector

        # Create a unique ID to capture test output
        params.uuid = uuid.v1()

        # Extract the test output as boolean
        captureTestOutput = (log) =>
          regexp = new RegExp "^\\[checkpoint\\] \\[#{params.uuid}\\] "
          if log.match regexp
            # Do nothing if successful as next step will be applied by the next
            # rule. But if it fails, either retry or exit
            if (log.replace regexp, '') is 'false'
              # TODO: implement retry
              @outPorts.exit.send data
              @outPorts.exit.disconnect()

            # Get rid of listener
            spooky.removeListener 'console', captureTestOutput

        # Place listener
        spooky.on 'console', captureTestOutput

        # Add a validation step
        spooky.then [params, ->
          # Wait for the specified selector to apply. Then test the condition.
          @waitForSelector selector, ->
            if property?
              v = @getElementAttribute selector, property
            else
              v = @getHTML selector
            console.log "[checkpoint] [#{uuid}] #{v is value}"

          , ->
            # Send to exit if it doesn't apply any more
            console.log "[checkpoint] [#{uuid}] false"
        ]

      # Pass onto the next rule
      @outPorts.out.send data

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()

exports.getComponent = -> new TestEffects
