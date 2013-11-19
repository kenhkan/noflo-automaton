_ = require 'lodash'
noflo = require 'noflo'

class Extract extends noflo.Component
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

        # Execute in browser space for output
        spooky.then [rule, ->
          @evaluate (selector, prop) ->
            # Get everything that matches
            elems = document.querySelectorAll selector

            # Get its property
            if prop?
              values = elems.map (i, elem) ->
                elem.getAttribute prop
            # Get the text if prop isn't defined
            else
              values = elems.map (i, elem) ->
                elem.innerHTML

            ## Output for capture
            console.log '[output] ' + JSON.stringify
              message: 'Values extracted'
              selector: selector
              property: prop
              values: values.toArray()

          # Need to use `prop` instead of `property` internally because of some
          # weird CasperJS peculiarity
          , selector, prop
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Extract
