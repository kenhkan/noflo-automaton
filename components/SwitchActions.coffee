noflo = require 'noflo'
_ = require 'underscore'

class SwitchActions extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port
    @outPorts =
      out: new noflo.Port
      action: new noflo.ArrayPort

    @inPorts.in.on 'data', (data) =>
      rule = data.rules[data.offset]

      # Set the number of actions and forward context object to OUT
      data.counts.actions = rule.actions.length
      @outPorts.out.send data

      # Go through each action and send as individual packet
      _.each rule.actions, (action) =>
        a = _.clone action
        # Use rule's selector by default
        a.selector ?= rule.selector

        @outPorts.action.send a

    @inPorts.in.on 'disconnect', =>
      @outPorts.action.disconnect()
      @outPorts.out.disconnect()

exports.getComponent = -> new SwitchActions
