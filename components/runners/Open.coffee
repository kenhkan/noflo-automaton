_ = require 'lodash'
noflo = require 'noflo'

class Open extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'open'
        ###
        # Open a page by URL
        #
        # @param {String} url The URL to open
        ###
        { url } = rule

        spooky.thenOpen url

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Open
