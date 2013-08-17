noflo = require 'noflo'
_ = require 'underscore'
Spooky = require 'spooky'

class Setup extends noflo.Component
  constructor: ->
    @inPorts =
      url: new noflo.Port 'string'
      rules: new noflo.Port 'object'
      options: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.url.on 'data', (@url) =>
    @inPorts.rules.on 'data', (@rules) =>
    @inPorts.options.on 'data', (@options) =>

    @inPorts.url.on 'disconnect', =>
      @setup()
    @inPorts.rules.on 'disconnect', =>
      @setup()

  setup: ->
    @options ?= {}

    # Only continue if we have both URL and rules
    return unless @url and @rules

    # Input validity check
    isValidRuleObject = @isValidRuleObject @rules
    isValidOptionObject = @isValidOptionObject @options
    unless isValidRuleObject is true
      error = isValidRuleObject
    unless isValidOptionObject is true
      error = isValidOptionObject

    # Send to error on invalid input
    if error?
      e = new Error error
      e.url = @url
      e.rules = @rules
      e.options = @options

      throw e unless @outPorts.error.isAttached()
      @outPorts.error.send e
      @outPorts.error.disconnect()

    # Setup Spooky and continue if all is good
    else
      @setupSpooky()

    # Reset the cache either way
    delete @url
    delete @rules
    delete @options

  setupSpooky: ->
    rules = @rules
    url = @url
    options = @options

    # Create a Spooky instance
    spooky = new Spooky
      casper: options
    , (error) =>

      # Send to error if initialization fails
      if error
        e = new Error 'Failed to initialize SpookyJS'
        e.details = error
        e.url = url
        e.rules = rules
        e.options = options
        @outPorts.error.send e
        @outPorts.error.disconnect()
        return

      # Any error in Casper is reported
      spooky.on 'error', (e) ->
        console.error e

      # Output all console messages if verbose
      if options.verbose
        spooky.on 'console', (line) ->
          console.log line

      # Start with some page
      spooky.start url

      # Forward the packet
      @outPorts.out.send
        spooky: spooky
        rules: rules
        counts: {}
      @outPorts.out.disconnect()

  # Is the option object valid?
  isValidOptionObject: (options) ->
    _.every(options, (option) ->
      not _.isObject option
    ) or 'Options object is not valid'

  # Is the rule object valid?
  isValidRuleObject: (rules) ->
    unless _.isArray rules
      return 'Rule object must be an array'

    _.every rules, (rule) ->
      valid = _.isObject(rule) and
        _.isString(rule.selector) and
        _.isArray(rule.actions) and
        _.isArray(rule.conditions)

      unless valid
        return 'Rule object must contain a selector, actions, and conditions'

      for action in rule.actions
        unless _.isObject(action) and _.isString(action.action)
          return 'Rule object actions must contain an action property'

      for condition in rule.conditions
        unless _.isObject(condition) and _.isString(condition.value)
          return 'Rule object conditions must contain a value property'

      return true

exports.getComponent = -> new Setup
