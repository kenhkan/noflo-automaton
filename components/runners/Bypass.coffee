_ = require 'lodash'
noflo = require 'noflo'

class Bypass extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule, offset } = context

      if rule.action is 'bypass'
        ###
        # Bypass a number of rules ahead. This looks ahead of the rule set to
        # determine the correct number of rules as each action may use more
        # than one rule.
        #
        # @param {number} count Number of rules to bypass
        ###

        # Number of rules in the rule set
        ruleCount = rule.count
        # Total number of actions in the X number of rules
        actionCount = 0

        # Read ahead in the rule set to count the total number of rules
        _.each [1..ruleCount], (i) ->
          # Get the next xth rule
          _rule = context.rules[offset + i]
          # Load the action runner
          runner = require("#{__dirname}/#{_rule.action}")
          # Get number of actions in rule. Defualt is 1
          count = runner.getComponent().actionCount or 1
          # Increment the count
          actionCount += count

        # Bypass the rules
        spooky.then [{ count: actionCount }, ->
          @bypass count
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Bypass
