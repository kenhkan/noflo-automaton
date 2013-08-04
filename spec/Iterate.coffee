noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  Iterate = require '../components/Iterate.coffee'
else
  Iterate = require 'noflo-automaton/components/Iterate.js'

describe 'Iterate component', ->
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
      {
        selector: '.bar'
        actions: [
          { action: 'click' }
        ]
        conditions: [
          { condition: 'Bar' }
        ]
      }
      {
        selector: '.foobar'
      }
    ]

  beforeEach ->
    globals.pageEl = document.querySelector '.test-existence'

    globals.c = Iterate.getComponent()
    globals.in = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()
    globals.exit = noflo.internalSocket.createSocket()

    globals.c.inPorts.in.attach globals.in
    globals.c.outPorts.out.attach globals.out
    globals.c.outPorts.exit.attach globals.exit

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(globals.c.inPorts.in).to.be.an 'object'

    it 'should have an output port', ->
      chai.expect(globals.c.outPorts.out).to.be.an 'object'
      chai.expect(globals.c.outPorts.exit).to.be.an 'object'

  describe 'preconditions', ->
    it 'has a page object that is a DOM element', (done) ->
      globals.exit.on 'data', (data) ->
        chai.expect(data.status).to.equal false
        chai.expect(data.error.message).to.equal 'Page object not a DOM element'
        done()

      globals.in.send
        page: {}
        rules: globals.rules

  describe 'iterate the looper', ->
    it 'exits successfully upon no more rules', (done) ->
      globals.exit.on 'data', (data) ->
        chai.expect(data.status).to.equal true
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules
        status: 100

    it 'initialize status if it is not defined', (done) ->
      globals.out.once 'data', (data) ->
        chai.expect(data.status).to.equal 0
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules

    it 'initialize status if it is not a number', (done) ->
      globals.out.once 'data', (data) ->
        chai.expect(data.status).to.equal 0
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules

    it 'initialize status if it is not a number', (done) ->
      globals.out.once 'data', (data) ->
        chai.expect(data.status).to.equal 0
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules
        status: true

    it 'increments status if it is provided', (done) ->
      globals.out.once 'data', (data) ->
        chai.expect(data.status).to.equal 1
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules
        status: 0

    it 'checks the validity of the structure of the next rule', (done) ->
      globals.exit.once 'data', (data) ->
        chai.expect(data.status).to.equal 2
        chai.expect(data.error.message).to.equal 'Invalid rule structure'
        done()

      globals.in.send
        page: globals.pageEl
        rules: globals.rules
        status: 1
