noflo = require 'noflo'
_ = require 'underscore'

class Iterate extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      exit: new noflo.Port 'object'

    @inPorts.in.on 'data', (data) =>
      # Page must be a DOM element
      unless data.page instanceof HTMLElement
        data.status = false
        data.error = new Error 'Page object not a DOM element'
        @outPorts.exit.send data
        return

      # Initialize a status number if it's not defined or not a number
      if data.status? and _.isNumber data.status
        data.status++
      else
        data.status = 0

      # Quit successfully upon no more rules
      if data.status >= data.rules.length
        data.status = true
        @outPorts.exit.send data
        return

      # The next rule must be valid in structure
      nextRule = data.rules[data.status]
      unless @isValidRule nextRule
        data.error = new Error 'Invalid rule structure'
        @outPorts.exit.send data
        return

      # Forward to OUT with incremented status
      @outPorts.out.send data

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect()
      @outPorts.exit.disconnect()

  isValidRule: (rule) ->
    valid = _.isObject(rule) and
      _.isString(rule.selector) and
      _.isArray(rule.actions) and
      _.isArray(rule.conditions)

    return false unless valid

    for action in rule.actions
      unless _.isObject(action) and _.isString(action.action)
        valid = false

    return false unless valid

    for condition in rule.conditions
      unless _.isObject(condition) and _.isString(condition.condition)
        valid = false

    return true

exports.getComponent = -> new Iterate
