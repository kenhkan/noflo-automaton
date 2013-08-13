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
    unless @isValidRuleObject @rules
      error = 'Rule object is not valid'
    unless @isValidOptionObject @options
      error = 'Options object is not valid'

    # Send to error on invalid input
    if error?
      e = new Error error
      e.url = @url
      e.rules = @rules
      e.options = @options
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
    , (error) ->

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

      # TODO: this should be in automaton/Run
      # Capture end of navigation
      #spooky.on 'log', (log) ->
      #  if log.space is 'remote'
      #    _.extend accum, JSON.parse log.message

      # Forward the packet
      @outPorts.out.send
        spooky: spooky
        rules: rules
        offset: 0
        counts: {}
      @outPorts.out.disconnect()

  # Is the option object valid?
  isValidOptionObject: (options) ->
    _.every options, (option) ->
      not _.isObject option

  # Is the rule object valid?
  isValidRuleObject: (rules) ->
    _.isArray(rules) and _.every rules, (rule) ->
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

exports.getComponent = -> new Setup
