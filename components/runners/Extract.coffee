_ = require 'lodash'
noflo = require 'noflo'
testSelector = require '../../common/testSelector'

class Extract extends noflo.Component
  actionCount: 2

  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule, offset } = context

      if rule.action is 'extract'
        ###
        # Extract some value out of an element by selector
        #
        # @param {String} selector The CSS selector
        # @param {String=} prop The property to extract
        ###
        rule.prop = rule.property or null

        testSelector spooky, rule.selector, context.offset

        # Execute in browser space for output
        spooky.then [rule, ->
          output = @evaluate (selector, prop) ->
            values = []
            # Get everything that matches
            elems = document.querySelectorAll selector

            # Get its property
            if prop?
              for elem in elems
                values.push elem.getAttribute prop
            # Get the text if prop isn't defined
            else
              for elem in elems
                values.push elem.innerHTML

            # Output for capture
            JSON.stringify
              message: 'Values extracted'
              selector: selector
              property: prop
              values: values

          # Need to use `prop` instead of `property` internally because of some
          # weird CasperJS peculiarity
          , selector, prop

          @log output, 'info', 'output'
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Extract
