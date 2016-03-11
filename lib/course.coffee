_     = require 'lodash'
Clip  = require './clip'
tools = require './helpers'

class Course
	constructor: (opts)->
    throw "title, index, moduleName and clips properties required" unless opts?.title or opts?.index or opts?.clips or opts?.moduleName

    @title = opts.title
    @moduleName = opts.moduleName
    @index = opts.index
    @clips = (new Clip({module: opts.index, clip: clip, moduleName: opts.moduleName }) for clip in opts.clips)

  find: (index)->
    _.find @clips, (c)-> c.clipIndex is index

  fullTitle: =>
    "#{@index + 1}. #{@title}"

  toc: =>
    console.log @fullTitle()
    @clips.forEach (clip)->
      clip.toc()
    console.log ""

module.exports = Course
