noflo = require 'noflo'
Q = require 'q'

class Automaton
  constructor: (params) ->
    { @name, @casperOptions } = params

  ###
  # Run a rule set
  #
  # @param {Object[]} rules The rule set
  # @returns {Promise} The result wrapped in a promise
  ###
  run: (rules) ->
    deferred = Q.defer()
    outBuffer = []
    errBuffer = []

    # Create the graph
    #graph = noflo.graph.createGraph 'automaton'
    #graph.addNode 'Automaton', 'automaton/Automaton'

    # Load the graph
    #noflo.createNetwork graph, (network) ->
    noflo.graph.loadFBP "'abc' -> IN Automaton(automaton/Automaton)", (graph) ->
      noflo.createNetwork graph, (network) ->
        { inPorts, outPorts } = network.processes.Automaton.component

        # Run it
        network.start()

        # Attach a receiver for errors
        errSocket = noflo.internalSocket.createSocket()
        outPorts.error.attach errSocket
        errSocket.on 'data', (data) ->
          errBuffer.push data
        errSocket.on 'disconnect', ->
          deferred.reject errBuffer

        # Attach a receiver for output
        outSocket = noflo.internalSocket.createSocket()
        outPorts.out.attach outSocket
        outSocket.on 'data', (data) ->
          outBuffer.push data
        outSocket.on 'disconnect', ->
          outBuffer.resolve outBuffer

        # Inject options
        optionsSocket = noflo.internalSocket.createSocket()
        inPorts.options.attach optionsSocket
        optionsSocket.connect()
        optionsSocket.send @casperOptions
        optionsSocket.disconnect()

        # Inject rule object
        rulesSocket = noflo.internalSocket.createSocket()
        inPorts.rules.attach rulesSocket
        rulesSocket.connect()
        rulesSocket.send rules
        rulesSocket.disconnect()

    # Return the promise
    deferred.promise

###
# Create a new Automaton instance
#
# @param {Object=} params A map of parameters
# @param {String} params.name A name for the NoFlo graph
# @param {Object} params.casperOptions Options to be passed to CasperJS
###
exports.create = (params = {}) ->
  new Automaton params
