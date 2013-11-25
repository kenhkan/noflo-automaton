_ = require 'lodash'
noflo = require 'noflo'

class Capture extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'capture'
        ###
        # Capture screenshot
        #
        # @param {String} path The path to the file to save the screenshot
        ###
        rule.path ?= 'screenshot.png'

        spooky.then [rule, ->
          @capture path
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Capture
