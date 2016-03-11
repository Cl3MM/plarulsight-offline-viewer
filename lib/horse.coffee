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
      .wait(300)
      .type '#Username', CONF.user
      .wait(300)
      .type '#Password', CONF.pass
      .wait(300)
      #.screenshot( tools.newPngPath() )
      .click("button:contains('Sign In')")
      .waitForNextPage()
      .open(@url)
      .waitForNextPage()
      .cookies()
      .then @scraper.setCookies
      .wait(200)
      #.screenshot tools.newPngPath()
      .wait(200)
      .html()
      .then @scraper.getModules
      .then @scraper.retrieveUrl
      .finally =>
        cb()

module.exports = Horse
