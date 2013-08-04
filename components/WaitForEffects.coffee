noflo = require 'noflo'

class TestExistence extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port
    @outPorts =
      out: new noflo.Port
      exit: new noflo.Port

    @inPorts.in.on 'begingroup', (group) ->

    @inPorts.in.on 'data', (data) ->

    @inPorts.in.on 'endgroup', (group) ->

    @inPorts.in.on 'disconnect', ->

exports.getComponent = -> new TestExistence
