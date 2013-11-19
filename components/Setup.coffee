noflo = require 'noflo'
_ = require 'underscore'
Spooky = require 'spooky'

class Setup extends noflo.Component
  constructor: ->
    @inPorts =
      rules: new noflo.Port 'object'
      options: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.rules.on 'data', (@rules) =>
    @inPorts.rules.on 'disconnect', => @setup()
    @inPorts.options.on 'data', (@options) =>

  # Set up only when there are rules
  setup: ->
    rules = @rules
    options = @options ?= {}

    # Reset the cache
    delete @rules
    delete @options

    # Only continue if we have rules
    return unless rules

    # Options should be an object
    unless _.isObject options
      return if @reportError new Error 'Options object is not valid'

    # Check rule set validity
    return if @reportError @isValidRuleSet rules

    # If everything is right, set Spooky up
    @setupSpooky()

  # Set up Spooky to run CasperJS
  setupSpooky: ->
    rules = @rules
    options = @options

    # Create a Spooky instance
    spooky = new Spooky
      casper: options
    , (error) =>
      # Send to error if initialization fails
      return if @reportError error

      # Spooky could have unlimited event listeners
      spooky.setMaxListeners 0

      # Any error in Casper is reported
      spooky.on 'error', (e) ->
        console.error e

      # Output all console messages if verbose
      if options.verbose
        spooky.on 'console', (line) ->
          console.log line

      # Forward the context object
      @outPorts.out.send
        spooky: spooky
        rules: rules
        counts: {}
      @outPorts.out.disconnect()

  ###
  # Report error, but only if the passed parameter is an error
  #
  # @param {Error} error The error to send along
  # @param {Boolean} True if the parameter is an error and is reported; false
  #   otherwise
  ###
  reportError: (error) ->
    return false unless error instanceof Error
    error.rules = @rules
    error.options = @options

    throw error unless @outPorts.error.isAttached()
    @outPorts.error.send error
    @outPorts.error.disconnect()
    return true

  ###
  # Is the rule object valid?
  #
  # @param {Object[]} rules The rule set
  # @returns {Error?} An error or null
  ###
  isValidRuleSet: (rules) ->
    unless _.isArray rules
      return new Error 'Rule set must be an array'
    unless rules.length > 0
      return new Error 'Empty rule set'

    for rule in rules
      unless _.isObject rule
        return new Error 'A rule must be an object'
      unless _.isString rule.action
        return new Error 'A rule must contain an action'

exports.getComponent = -> new Setup
