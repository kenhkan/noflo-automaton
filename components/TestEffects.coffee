_ = require 'underscore'
noflo = require 'noflo'

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
      _.each rule.conditions, (condition) ->
        condition.selector ?= selector

        # Add a validation step
        spooky.then [condition, ->
          # Wait for the specified selector to apply. Then do nothing as the
          # next step will be applied by the next rule. But if it fails, either
          # retry or exit
          @waitForSelector selector, (->), ->
            # TODO: implement retry
            # Send to exit if it doesn't apply any more
            console.log 'EXIT'
        ]

      # Pass onto the next rule
      @outPorts.out.send data

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()

exports.getComponent = -> new TestEffects
