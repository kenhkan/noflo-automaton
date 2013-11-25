module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-conventional-changelog'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-bump'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-nodeunit'

  # Project configuration
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    # Automatic changelog
    changelog:
      options:
        dest: 'CHANGELOG.md'
        template: 'etc/changelog.tpl'

    # Bump version to both Bower and NPM
    bump:
      options:
        files: ['package.json']
        commit: true
        commitMessage: 'chore(release): v%VERSION%'
        commitFiles: ['package.json']
        createTag: true
        tagName: 'v%VERSION%'
        tagMessage: 'Version %VERSION%'
        push: false
        pushTo: 'origin'

    # Automated recompilation and testing when developing
    watch:
      files: ['spec/*.coffee', 'components/*.coffee']
      tasks: ['test']

    # Coding standards
    coffeelint:
      components: ['components/*.coffee']

    # NodeUnit tests
    nodeunit:
      all: ['spec/*.coffee']

  # Grunt plugins used for testing
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-nodeunit'
  grunt.loadNpmTasks 'grunt-coffeelint'

  # Our local tasks
  grunt.registerTask 'test', 'Build NoFlo and run automated tests', (target = 'all') =>
    grunt.task.run 'coffeelint'
    grunt.task.run 'nodeunit'

  grunt.registerTask 'default', ['test']
