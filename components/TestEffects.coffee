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

        # Figure out how many steps to skip if the condition fails
        nextName = condition.onFailure
        if nextName?
          nextOffset = @findNext context.rules, offset, nextName
          params.stepsOnFailure = nextOffset - offset

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

        # Stringify params for transfer
        params = { params: JSON.stringify(params) }

        # Add a validation step
        spooky.then [params, ->
          {
            value
            property
            selector
            onFailure
            offset
            uuid
            stepsOnFailure
          } = JSON.parse params

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

            # If `evaluate()` cannot handle it, exit
            isHandled = @evaluate (uuid, offset, v, value, stepsOnFailure) ->
              isValid = not v? or v is value
              console.log "[checkpoint] [#{uuid}] #{isValid}"

              # Report if invalid
              unless isValid
                # Try to skip if there is a name
                if stepsOnFailure?
                  # Hack: see TestActions on `bypass()`
                  window._bypass ?= 0
                  window._bypass += stepsOnFailure
                  return true

                # Output error otherwise
                else
                  output =
                    message: 'condition invalid'
                    offset: offset
                    expected: value
                    actual: v
                  console.log "[output] #{JSON.stringify output}"
                  # Exit
                  return false

              # Assume that we've handled it
              true
            , uuid, offset, v, value, stepsOnFailure

            # Quit if unhandled
            @exit() unless isHandled

          , ->
            # Not valid if timed out
            @evaluate (uuid) ->
              console.log "[checkpoint] [#{uuid}] false"
            , uuid

            # Report failing post-condition
            isValid = @evaluate (offset, selector, value, stepsOnFailure) ->
              # Skip some steps
              if stepsOnFailure?
                # Hack: see TestActions on `bypass()`
                window._bypass ?= 0
                window._bypass += stepsOnFailure
                return true
              # Output and exit otherwise
              else
                output =
                  message: 'condition selector does not exist'
                  offset:  offset
                  selector: selector
                output.value = value if value?
                console.log "[output] #{JSON.stringify output}"
            , offset, selector, value, stepsOnFailure

            # Do not proceed
            @exit() unless isValid
        ]

      # Pass onto the next rule
      @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()

  # Helper to find the next rule by name from current position
  findNext: (rules, offset, name) ->
    while offset < rules.length
      rule = rules[offset]

      if name is rule.name
        return offset
      else
        offset++

exports.getComponent = -> new TestEffects
