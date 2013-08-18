_s = require 'underscore.string'
noflo = require 'noflo'

globals = {}

# Hook into stdout to capture graph's output
# Adopted from https://gist.github.com/pguillory/729616
_hookStdout = (callback) ->
  oldWrite = process.stdout.write

  process.stdout.write = ((write) ->
    (string, encoding, fd) ->
      write.apply process.stdout, arguments
      callback string, encoding, fd
  )(process.stdout.write)

  ->
    process.stdout.write = oldWrite

 # Hook into stdout and call the callback when done with the output and the
 # unhook function
hookStdout = (done) ->
  _unhookStdout = _hookStdout (string, encoding, fd) ->
    # Extract output encoded in base64
    string = _s.trim string.replace /'/g, ''
    regexp = new RegExp "^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$"
    [output] = string.match(regexp) or []
    if output?
      output = JSON.parse new Buffer(output, 'base64').toString()
      done output, _unhookStdout

module.exports =
  setUp: (done) ->
    globals.testRulesSuccess = [
      {
        selector: 'form[name="f"]'
        actions: [
          {
            action: 'fill'
            selector: 'form[name="f"]'
            form:
              q: 'Search Terms'
          }
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Search Terms', property: 'value', selector: 'form input[type="text"]' }
          { value: 'Search', selector: '#gb_1 .gbts' }
        ]
      }
      {
        selector: 'a[href="/intl/en/about.html"]'
        actions: [
          { action: 'extract' }
        ]
        conditions: []
      }
    ]
    globals.testRulesFailAction = [
      {
        selector: 'form[name="f"]'
        actions: [
          {
            action: 'fill'
            selector: 'form[name="f"]'
            form:
              q: 'Search Terms'
          }
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Search Terms', property: 'value', selector: 'form input[type="text"]' }
          { value: 'Search', selector: '#gb_1 .gbts' }
        ]
      }
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'click', selector: 'input[name="btnNotExist"]' }
        ]
        conditions: [
          { value: 'Search', selector: '#gb_1 .gbts' }
        ]
      }
    ]
    globals.testRulesFailCondition = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Search Terms'}
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Google Search', property: 'value', selector: 'form input[type="text"]' }
          { value: 'Search', selector: '#gb_1 .gbts' }
        ]
      }
      {
        selector: 'form[name="gs"]'
        actions: [
          {
            action: 'fill'
            form:
              q: 'Google Search'
          }
          { action: 'click', selector: 'button[name="btnG"]' }
        ]
        conditions: [
          { value: 'Not this search', property: 'value', selector: 'form input[type="text"]' }
        ]
      }
    ]

    globals.runAutomaton = (test, context) ->
      fbp = """
        '#{context.url}' -> URL Automaton(automaton/Automaton) OUT -> IN Jsonify(strings/Jsonify) OUT -> IN ToBaseSixFour(strings/ConvertEncoding) OUT -> IN Output(core/Output)
        '#{JSON.stringify context.rules}' -> IN ParseJson(strings/ParseJson) OUT -> RULES Automaton()
      """

      noflo.graph.loadFBP fbp, (graph) ->
        noflo.createNetwork graph, (network) ->
          console.log 'Network is ready'

    done()

  'the automaton system':
    'successfully run the graph': (test) ->
      hookStdout (output, unhook) ->
        unhook()
        test.deepEqual output, [
          message: 'value extracted'
          offset: 1
          selector: 'a[href="/intl/en/about.html"]'
          property: null
          value: 'About Google'
        ]
        test.done()

      globals.runAutomaton test,
        url: 'http://www.google.com'
        rules: globals.testRulesSuccess

    'run the graph with failing action (i.e. element does not exist)': (test) ->
      hookStdout (output, unhook) ->
        unhook()
        test.deepEqual output, [
          message: 'action selector does not exist'
          offset: 1
          selector: 'input[name="btnNotExist"]'
        ]
        test.done()

      globals.runAutomaton test,
        url: 'http://www.google.com'
        rules: globals.testRulesFailAction

    'run the graph with failing post-condition': (test) ->
      hookStdout (output, unhook) ->
        unhook()
        test.deepEqual output, [
          message: 'condition invalid'
          offset: 0
          expected: 'Google Search'
          actual: 'Search Terms'
        ]
        test.done()

      globals.runAutomaton test,
        url: 'http://www.google.com'
        rules: globals.testRulesFailCondition
