_        = require 'lodash'
fs       = require 'fs-extra'
tools    = require './helpers'
CONF     = require './config'
Horse    = require './horse'
queue    = require 'queue'
Horseman = require "node-horseman"

q        = queue(concurrency: 1)
horseman = new Horseman(loadImages: false)

CONF.urls.forEach (url)->
  horse = new Horse(url: url, horseman: horseman)
  q.push horse.go

start = new Date().getTime()
q.start (err)->
  if (err)
    console.log '[!] An error has occured'
    return
  console.log 'All tasks completed in ' + (new Date().getTime() - start) / 1000 / 60 + ' min'
  horseman.close()
