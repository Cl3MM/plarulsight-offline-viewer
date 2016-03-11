util = require 'util'
_    = require 'lodash'
CONF = require './config'

log = (obj)->
  console.log(util.inspect(obj, false, null))

generateFileName = (ext, path)->
  rnd   = _.random(0, 100)
  ticks = new Date().getTime()
  file  = "#{path}#{ticks}_#{rnd}.#{ext}"
  console.log "[+] File name:", file if CONF.debug > 0
  file

generatePng = ->
  generateFileName('png', CONF.screenshots_path)

generateHtml = ->
  generateFileName('html', CONF.assets_path)

module.exports = {
  newPngPath  : generatePng
  newHtmlPath : generateHtml
  log         : log
}
