noflo = require 'noflo'
testSelector = require '../../common/testSelector'

class Select extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'

    @inPorts.in.on 'data', (context) =>
      { spooky, rule } = context

      if rule.action is 'select'
        ###
        # Select an option from a dropbox
        #
        # @param {String} selector The CSS selector
        # @param {String} value The value to select
        ###
        testSelector spooky, rule.selector, context.offset

        spooky.then [rule, ->
          @evaluate (selector, value) ->
            selectEl = document.querySelector selector
            for option, i in selectEl.options
              if option.value is value
                selectEl.selectedIndex = i
                break
          , selector, value
        ]

      else if @outPorts.out.isAttached()
        @outPorts.out.send context

    @inPorts.in.on 'disconnect', =>
      if @outPorts.out.isAttached()
        @outPorts.out.disconnect()

exports.getComponent = -> new Select
