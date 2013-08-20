_ = require 'underscore'
noflo = require 'noflo'

class Extract extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, action } = context

      # Extract
      if action.action is 'extract'
        _action = _.clone action
        _action.offset = context.offset
        _action.prop = action.property or null

        # Execute in browser space for output
        spooky.then [_action, ->
          @evaluate (offset, selector, prop) ->
            # Get the text if prop isn't defined
            elems = $(selector)
            if prop?
              values = elems.map (i, elem) ->
                elem.getAttribute prop
            else
              values = elems.map (i, elem) ->
                elem.innerText

            ## Output for capture
            console.log '[output] ' + JSON.stringify
              message: 'values extracted'
              offset: offset
              selector: selector
              property: prop
              values: values.toArray()

          # Need to use `prop` instead of `property` internally because of some
          # weird Casper.js peculiarity
          , offset, selector, prop
        ]

      # Forward otherwise
      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Extract
