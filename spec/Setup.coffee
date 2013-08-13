noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  Setup = require '../components/Setup.coffee'
else
  Setup = require 'noflo-automaton/components/Setup.js'

describe 'Setup component', ->
  globals = {}

  beforeEach ->
    globals.testUrl = 'http://noflojs.org'
    globals.testRules = [
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
    ]

    globals.c = Setup.getComponent()
    globals.url = noflo.internalSocket.createSocket()
    globals.rules = noflo.internalSocket.createSocket()
    globals.options = noflo.internalSocket.createSocket()
    globals.out = noflo.internalSocket.createSocket()
    globals.error = noflo.internalSocket.createSocket()

    globals.c.inPorts.url.attach globals.url
    globals.c.inPorts.rules.attach globals.rules
    globals.c.inPorts.options.attach globals.options
    globals.c.outPorts.out.attach globals.out
    globals.c.outPorts.error.attach globals.error

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(globals.c.inPorts.url).to.be.an 'object'
      chai.expect(globals.c.inPorts.rules).to.be.an 'object'
      chai.expect(globals.c.inPorts.options).to.be.an 'object'

    it 'should have an output port', ->
      chai.expect(globals.c.outPorts.out).to.be.an 'object'
      chai.expect(globals.c.outPorts.error).to.be.an 'object'

  describe 'preconditions', ->
    it 'receives a valid rule object', (done) ->
      globals.error.on 'data', (data) ->
        chai.expect(data.message).to.equal 'Rule object is not valid'
        done()

      globals.url.send globals.testUrl
      globals.rules.send {}
      globals.url.disconnect()
      globals.rules.disconnect()

    it 'receives a valid options object', (done) ->
      globals.error.on 'data', (data) ->
        chai.expect(data.message).to.equal 'Options object is not valid'
        done()

      globals.url.send globals.testUrl
      globals.rules.send []
      globals.options.send
        invalid:
          dictionary: 'when'
          it: 'is nested'
      globals.url.disconnect()
      globals.rules.disconnect()
      globals.options.disconnect()

  describe 'SpookyJS setup', ->
    it 'starts with the provided URL and options', (done) ->
      globals.out.on 'data', (data) ->
        chai.expect(data.spooky.then).to.be.a.function
        chai.expect(data.spooky.thenEvaluate).to.be.a.function
        chai.expect(data.rules).to.be.an.array
        chai.expect(data.offset).to.be.a.number
        chai.expect(data.counts).to.be.an.object
        done()

      globals.url.send globals.testUrl
      globals.rules.send globals.testRules
      globals.options.send
        verbose: true
      globals.url.disconnect()
      globals.rules.disconnect()
      globals.options.disconnect()

    it 'starts with the provided URL but no options', (done) ->
      globals.out.on 'data', (data) ->
        chai.expect(data.spooky.then).to.be.a.function
        chai.expect(data.spooky.thenEvaluate).to.be.a.function
        chai.expect(data.rules).to.be.an.array
        chai.expect(data.offset).to.be.a.number
        chai.expect(data.counts).to.be.an.object
        done()

      globals.url.send globals.testUrl
      globals.rules.send globals.testRules
      globals.url.disconnect()
      globals.rules.disconnect()
