noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  TestExistence = require '../components/TestExistence.coffee'
else
  TestExistence = require 'noflo-automaton/components/TestExistence.js'

describe 'TestExistence component', ->
  globals =
    rules: [
      {
        selector: '.foo'
        actions: [
          { action: 'click' }
          { action: 'click', selector: '.bar' }
        ]
        conditions: [
          { condition: 'Foo' }
          { condition: 'Bar', selector: '.bar' }
        ]
      }
    ]

  beforeEach ->
    globals.c = TestExistence.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.element = noflo.internalSocket.createSocket()
    globals.error = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()
    globals.exit = noflo.internalSocket.createSocket()
    globals.page = noflo.internalSocket.createSocket()
    globals.selector = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.inPorts.element.attach globals.element
    globals.c.inPorts.error.attach globals.error
    globals.c.outPorts.out.attach globals.out
    globals.c.outPorts.exit.attach globals.exit
    globals.c.outPorts.page.attach globals.page
    globals.c.outPorts.selector.attach globals.selector

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(globals.c.inPorts.in).to.be.an 'object'

    it 'should have an output port', ->
      chai.expect(globals.c.outPorts.out).to.be.an 'object'
      chai.expect(globals.c.outPorts.exit).to.be.an 'object'

  describe 'preconditions', ->
    it 'forwards to EXIT if OUT is not attached', (done) ->
      globals.c.outPorts.out.detach()

      globals.exit.once 'data', (data) ->
        chai.expect(data.status).to.equal 0
        chai.expect(data.page).to.equal document
        chai.expect(data.rules).to.deep.equal globals.rules
        done()

      globals.in.send
        page: document
        rules: globals.rules
        status: 0

  describe 'testing existence', ->
    beforeEach ->
      globals.pageEl = document.querySelector '.test-existence'

    it 'forwards the page and selector onto a dom/GetElement object', (done) ->
      globals.page.once 'data', (data) ->
        chai.expect(data).to.equal globals.pageEl
      globals.selector.once 'data', (data) ->
        chai.expect(data).to.equal '.foo'
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules
        status: 0

    it 'sends to OUT upon receiving an element', (done) ->
      el = globals.pageEl.querySelector '.exists'

      globals.out.once 'data', (data) ->
        chai.expect(data.status).to.equal 0
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules
        status: 0
      globals.element.send el

    it 'sends to EXIT upon receiving an error', (done) ->
      el = globals.pageEl.querySelector '.non-exists'

      globals.exit.once 'data', (data) ->
        chai.expect(data.status).to.equal 0
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules
        status: 0
      globals.error.send new Error 'Some noflo-dom error'
