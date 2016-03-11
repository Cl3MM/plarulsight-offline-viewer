CONF    = require './config'
url     = require 'url'
tools   = require './helpers'
cheerio = require 'cheerio'
Promise = require 'bluebird'
_       = require 'lodash'
fs      = require 'fs-extra'
request = require 'request'
Course  = require './course'
queue   = require 'queue'
URL     = require 'url'

class Pluralsight
  constructor: (opts)->
    throw "horseman and url required" unless opts?.horseman or opts?.url
    @url      = opts.url
    @query    = URL.parse(opts.url, true).query
    @horseman = opts.horseman
    @cookies  = null
    @modules  = []
    @psm      = null
    @jwt      = null

  setCookies: (cookies)=>
    new Promise (resolve, reject)=>
      @cookies = cookies
      tools.log cookies if CONF.debug > 1
      @psm     = _.find(cookies, (c)-> c.name is "PSM")?.value
      @jwt     = _.find(cookies, (c)-> c.name is "PsJwt-production")?.value
      console.log "PSM: ", @psm if CONF.debug > 0
      console.log "@jwt: ", @jwt if CONF.debug > 0

      if !@jwt or !@psm
        reject('no cookie found :S')
      console.log "[+] cookies found"
      return resolve()

  printModules : =>
    @modules.forEach (m)->
      m.toc()

  cookieHeaders: =>
    "PsJwt-production=#{@jwt}; PSM=#{@psm}"

  headers: (clip)=>
    cookies = @cookieHeaders()
    {
      Host             : "app.pluralsight.com"
      Connection       : 'keep-alive'
      Pragma           : 'no-cache'
      'Cache-Control'  : 'no-cache'
      Origin           : 'https://app.pluralsight.com'
      'User-Agent'     : CONF.ua
      'content-type'   : 'application/json;charset=UTF-8'
      Accept           : '*/*'
      Referer          : clip.referer()
      #Referer         : "https://app.pluralsight.com/player?course=docker-deep-dive&author=nigel-poulton&name=docker-deep-dive-m1&clip=1&mode=live"
      "Accept-Encoding": "gzip, deflate"
      "Accept-Language": "fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4"
      Cookie           : cookies
    }

  getVideoUrls: (module, q, clipIndex)=>
    console.log "[+] Getting clips for module #{module.index}" if CONF.debug > 0
    clips = if clipIndex then [module.find(clipIndex)] else module.clips
    clips.forEach( (clip)->
      exists = clip.localFileExists()
      options =
        url    : CONF.app + CONF.retrieveUrl
        headers: @headers(clip)
        method : 'POST'
        body   : clip.toJson()
        json   : true

      console.log '[+] Pushing promise' if CONF.debug > 0
      if !exists
        q.push (cb)->
          clip.getVideoUrls(options).then(cb).catch (err)->
            cb(err)
    , @)

  retrieveUrl: =>
    unless @modules
      console.log "[+] no modules found, exiting..."
      return @horseman
    console.log "[+] enqueueing modules "
    #console.log @cookieHeaders()
    #module = @modules[1]
    q = queue(concurrency: 1)
    @modules.forEach (module)=>
      @getVideoUrls module, q
    #@getVideoUrls @modules[1], q
    query = @query
    new Promise (resolve, reject)->
      console.log "[+] processing course: #{query.course}"
      start = new Date().getTime()
      q.start (err)->
        if (err)
          console.log '[!] Error processing the queue'
          tools.log err
          return reject()
        console.log '[+] Course '+query.course+' processed with success in ' + (new Date().getTime() - start) / 1000 / 60 + 'min'
        resolve()

  getModules : (html)=>
    modules = []
    query = @query
    $ = cheerio.load html
    console.log '[+] ' + $('.module').length + ' modules found'
    index = 0
    re = new RegExp /.*\$(.*)/
    $('.module').each (module)->
      clip = 0
      clips = []
      id = $(this).data('reactid')
      moduleName = re.exec(id)?[1]
      unless moduleName
        console.log '[!] unable to find the module name'
        return
      $(this).find('li h3').each ->
        clips.push {
          index: clip
          title: $(this).text()
          author: query.author
          course: query.course
        }
        clip += 1
      modules.push new Course(
        title: $(this).find('h2').text()
        moduleName: moduleName
        index: index
        module: query.course
        clips: clips
      )
      index += 1
    return @horseman unless modules[0]
    @modules = modules

    @writeToc(modules).then =>
      return @horseman

  writeToc: (modules)=>
    query            = url.parse(@url, true).query
    courseName      = query.course
    file       = "#{CONF.video_path}#{courseName}/toc.txt"
    content = []
    modules.forEach (m)->
      content.push m.fullTitle()
      m.clips.forEach (clip)->
        content.push clip.fullTitle()
      content.push ""

    new Promise (resolve, reject)->
      fs.outputFile file, content.join('\r\n'), (err)->
        if (err)
          return reject()
        resolve()

module.exports = Pluralsight
