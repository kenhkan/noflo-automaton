module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # Automated recompilation and testing when developing
    watch:
      files: ['spec/*.coffee', 'components/*.coffee']
      tasks: ['test']

    # Coding standards
    coffeelint:
      components: ['components/*.coffee']

    # NodeUnit tests
    nodeunit:
      all: ['test/*.coffee']

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-contrib-nodeunit'
  @loadNpmTasks 'grunt-coffeelint'

  # Our local tasks
  @registerTask 'test', 'Build NoFlo and run automated tests', (target = 'all') =>
    @task.run 'coffeelint'
    @task.run 'nodeunit'

  @registerTask 'default', ['test']
