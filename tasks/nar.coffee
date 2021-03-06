hu = require 'hu'
{ parallel } = require 'fw'
{ resolve } = require 'requireg'

module.exports = (grunt) ->
  nar = null
  narPath = resolve 'nar'

  grunt.registerMultiTask 'nar', 'Create and extract nar archives', ->

    archives = []
    done = @async()
    options = @options mode: 'create'

    narError() unless narPath
    nar = require narPath

    onError = (err) ->
      grunt.fail.warn "Task failed: #{err}"
      done()

    onSuccess = ->
      grunt.log.writeln "Task completed successfully"
      done()

    @files.forEach (f) ->
      archives = archives.concat f.src
        .filter((filepath) -> grunt.file.exists filepath)
        .map (filepath) ->
          config = hu.clone options
          config.path = filepath
          config.dest = f.dest

          if options.mode is 'create'
            create config
          else
            extract config

      grunt.file.mkdir f.dest unless grunt.file.exists f.dest

    parallel archives, (err) ->
      return onError err if err
      onSuccess()

  create = (options) -> (done) ->
    if options.executable
      archive = nar.createExec options
    else
      archive = nar.create options

    archive
      .on('entry', (entry) ->
        grunt.verbose.writeln "Adding file: #{entry.path or entry.name}"
      ).on('error', (err) ->
        grunt.log.error "Cannot create archive: #{err}"
        done err
      ).on 'end', (path) ->
        grunt.log.writeln "Archive created in: #{path}"
        done()

  extract = (options) -> (done) ->
    nar.extract(options)
      .on('entry', (entry) ->
        grunt.verbose.writeln "Extracting file: #{entry.path or entry.name}"
      ).on('error', (err) ->
        grunt.log.error "Cannot extract archive: #{err}"
        done err
      ).on 'end', (info) ->
        grunt.log.writeln "Archive extracted in: #{info.dest}"
        done()

  narError = ->
    grunt.fail.fatal """

    nar is not installed as global package

    You must install it. Run:
    npm install -g nar

    """
