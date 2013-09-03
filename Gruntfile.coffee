module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    clean:
      build: ['public/javascripts/app/build/']
      dist: ['public/javascripts/app/dist/']

    jade:
      compile:
        expand: true
        cwd: 'public/templates/jade'
        src: ['**/*.jade']
        dest: 'public/templates/'
        ext: '.html'

    stylus:
      compile:
        expand: true
        cwd: 'public/stylesheets/stylus'
        src: ['**/*.styl']
        dest: 'public/stylesheets/'
        ext: '.css'

    coffee:
      compile:
        expand: true
        cwd: 'public/javascripts/app/src/'
        src: ['**/*.coffee']
        dest: 'public/javascripts/app/build/'
        ext: '.js'

    concat:
      options:
        seperator: ';'
      dist:
        src: ['public/javascripts/app/build/**/*.js']
        dest: 'public/javascripts/app/dist/<%= pkg.name %>.js'

    uglify:
      options:
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
        mangle: false
      dist:
        files:
          'public/javascripts/app/dist/<%= pkg.name %>.min.js': ['<%= concat.dist.dest %>']

    watch:
      coffee:
        files: ['<%= coffee.compile.src %>']
        tasks: ['coffee', 'concat', 'uglify']
      stylus:
        files: ['<%= stylus.compile.src %>']
        tasks: ['stylus']
      jade:
        files: ['<%= jade.compile.src %>']
        tasks: ['jade']

  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['clean', 'jade', 'stylus', 'coffee', 'concat', 'uglify']
  grunt.registerTask 'dev', ['default', 'watch']
