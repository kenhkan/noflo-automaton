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
      offset = context.offset
      rule = context.rules[offset]
      spooky = context.spooky
      selector = rule.selector

      # Offset should only be incremented once per rule
      incrementOffset = _.once ->
        context.offset++

      # Test each condition
      _.each rule.conditions, (condition) =>
        params = _.clone condition
        params.selector ?= selector
        params.value ?= null
        params.offset = offset
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
            # Extract an attribute
            v = if property?
              @getElementAttribute selector, property
            # The contained HTML
            else if value?
              @getHTML selector
            # Nothing
            else
              null

            # Report validity checkpoint, but only if there's a value to
            # compare. Otherwise, always report `true`.
            isValid = @evaluate (uuid, offset, v, value) ->
              isValid = not v? or v is value
              console.log "[checkpoint] [#{uuid}] #{isValid}"

              # Report if invalid
              unless isValid
                output =
                  message: 'condition invalid'
                  offset: offset
                  expected: value
                  actual: v
                console.log "[output] #{JSON.stringify output}"

              # Return validity
              isValid
            , uuid, offset, v, value

            # Do not proceed if invalid
            @exit() unless isValid

          , ->
            # Not valid if timed out
            @evaluate (uuid) ->
              console.log "[checkpoint] [#{uuid}] false"
            , uuid

            # Report failing post-condition
            @evaluate (offset, selector, value) ->
              output =
                message: 'condition selector does not exist'
                offset:  offset
                selector: selector
              output.value = value if value?
              console.log "[output] #{JSON.stringify output}"
            , offset, selector, value

            # Do not proceed
            @exit()
        ]

      # Pass onto the next rule
      @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()

exports.getComponent = -> new TestEffects
