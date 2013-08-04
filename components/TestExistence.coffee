noflo = require 'noflo'

class TestExistence extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'
      element: new noflo.Port 'object'
      error: new noflo.Port 'object'
    @outPorts =
      out: new noflo.Port 'object'
      exit: new noflo.Port 'object'
      page: new noflo.Port 'object'
      selector: new noflo.Port 'string'

    @inPorts.in.on 'data', (@context) =>
      page = @context.page
      selector = @context.rules[@context.status].selector

      @outPorts.page.send page
      @outPorts.selector.send selector

    @inPorts.in.on 'disconnect', =>
      @outPorts.page.disconnect()
      @outPorts.selector.disconnect()

    @inPorts.element.on 'data', (data) =>
      @outPorts.out.send @context

    @inPorts.element.on 'disconnect', =>
      @outPorts.out.disconnect()

    @inPorts.error.on 'data', (data) =>
      @context.error = data
      @outPorts.exit.send @context

    @inPorts.error.on 'disconnect', =>
      @outPorts.exit.disconnect()

exports.getComponent = -> new TestExistence
