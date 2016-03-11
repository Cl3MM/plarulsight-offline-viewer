Pluralsight = require './pluralsight'
tools       = require './helpers'
CONF        = require './config'
_           = require 'lodash'

class Horse
  constructor: (opts)->
    @url      = opts.url
    @horseman = opts.horseman
    @scraper  = new Pluralsight(horseman: opts.horseman, url: opts.url)

  go: (cb)=>
    @horseman
      .viewport(1980,1200)
      .userAgent CONF.ua
      .open CONF.root
      .wait(CONF.wait)
      .type '#Username', CONF.user
      .wait(CONF.wait)
      .type '#Password', CONF.pass
      .wait(CONF.wait)
      #.screenshot( tools.newPngPath() )
      .click("button:contains('Sign In')")
      .waitForNextPage()
      .open(@url)
      .waitForNextPage()
      .cookies()
      .then @scraper.setCookies
      .wait(CONF.wait)
      .screenshot tools.newPngPath()
      #.wait(CONF.wait)
      .html()
      .then @scraper.getModules
      .then @scraper.retrieveUrl
      .finally =>
        cb()

module.exports = Horse
