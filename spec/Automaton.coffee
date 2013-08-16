util = require 'util'
noflo = require 'noflo'

globals = {}

# Hook into stdout to capture graph's output
# Adopted from https://gist.github.com/pguillory/729616
hookStdout = (callback) ->
  oldWrite = process.stdout.write

  process.stdout.write = ((write) ->
    (string, encoding, fd) ->
      write.apply process.stdout, arguments
      callback string, encoding, fd
  )(process.stdout.write)

  ->
    process.stdout.write = oldWrite

unhookStdout =  hookStdout (string, encoding, fd) ->
  util.debug "[stdout] #{util.inspect string}"

module.exports =
  setUp: (done) ->
    globals.testRulesSuccess = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Google Search', property: 'value', selector: 'form input[type="text"]' }
          { value: 'Search', selector: 'div#ab_name span' }
        ]
      }
    ]
    globals.testRulesFail = [
      {
        selector: 'input[name="q"]'
        actions: [
          { action: 'value', value: 'Google Search' }
          { action: 'click', selector: 'input[name="btnG"]' }
        ]
        conditions: [
          { value: 'Not this search', property: 'value', selector: 'form input[type="text"]' }
        ]
      }
    ]

    globals.runAutomaton = (context) ->
      fbp = """
        '#{context.url}' -> URL Automaton(automaton/Automaton) OUT -> IN Output(core/Output)
        '#{JSON.stringify context.rules}' -> IN ParseJson(strings/ParseJson) OUT -> RULES Automaton()
      """

      noflo.graph.loadFBP fbp, (graph) ->
        noflo.createNetwork graph, (network) ->
          console.log 'Network is ready'

    done()

  'the automaton system':
    'successfully run the graph': (test) ->
      globals.runAutomaton
        url: 'http://www.google.com'
        rules: globals.testRulesSuccess

      test.done()

    'unhooks stdout (this is not a test)': (test) ->
      unhookStdout()
      test.done()
