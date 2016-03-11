fs          = require 'fs-extra'
path        = require 'path'
CONF        = require './config'
Promise     = require 'bluebird'
_           = require 'lodash'
request     = require 'request'
tools       = require './helpers'
ProgressBar = require 'progress'

class Clip
  # opts = {
  #   module: module # int
  #   clip: clip # { index: 0, title: "clip title" }
  # }
  constructor: (opts)->
    unless opts?.module or opts?.clip or opt?.moduleName
      throw "clip, moduleName and module params are required"
    @title           = opts.clip.title
    @module          = opts.module
    @author          = opts.clip.author
    @clipIndex       = opts.clip.index
    @courseName      = opts.clip.course
    @locale          = "en"
    @includeCaptions = false
    @mediaType       = opts?.format ? "mp4"
    @moduleName      = opts.moduleName
    @quality         = opts?.resolution ? "1280x720"
    @courseDir       = "#{CONF.video_path}#{@courseName}/"
    validFileName    = @fullTitle().replace(/,|\?|\*|\\|\+|\%|:|\/|!|\||"|<|>|\$|\^| /g ,'_')
    @fname           = "#{@courseDir}#{validFileName}.mp4"
    @retry           = 3
    @

  fullTitle: =>
    "#{@module + 1}.#{@clipIndex + 1} #{@title}"
  toc: ->
    console.log "#{@module + 1}.#{@clipIndex + 1} #{@title}"

  referer: ->
    "https://app.pluralsight.com/player?course=#{@courseName}&author=#{@author}&name=#{@moduleName}&clip=#{@clipIndex}&mode=live"

  toJson: ->
    {
      author         : @author
      clipIndex      : @clipIndex
      courseName     : @courseName
      includeCaptions: false
      locale         : "en"
      mediaType      : "mp4"
      moduleName     : @moduleName
      quality        : "1280x720"
    }

  getVideoUrls: (options)->
    console.log '[+] getting video urls for clip ' + @fullTitle() if CONF.debug > 0
    return new Promise (resolve, reject)=>
      fs.access @fname, fs.F_OK, (err)=>
        if (!err)
          console.log "[!] file #{@fullTitle()} exists, skipping..."
          # file exists, we skip
          return resolve()
        # file does not exist, we downlad
        request(options, @callback(options, resolve, reject))

  callback: (options, resolve, reject)=>
    console.log '[+] creating callback for clip ' + @fullTitle() if CONF.debug > 0

    return (err, response, body)=>
      if(err or response.statusCode isnt 200)
        console.log '[x] response error'
        tools.log err
        console.log '[x] response body'
        tools.log body
        console.log '[x] request options'
        tools.log options
        if response.statusCode is 429 and @retry > 0
          console.log '[x] requeing request strike #' + 4 - @retry
          @retry -= 1
          setTimeout( ->
            console.log '[x] dequeing request'
            request(options, callback(options, resolve, reject))
            return
          , _.random(120, 800))
          return
        # moving to the next promise
        return resolve(err)
      console.log '[+] Gotz response' if CONF.debug > 0
      tools.log body if CONF.debug > 0
      urls = body?.urls?.map (u)-> u.url
      unless urls[0]
        console.log "[!] error, response contains no valid url"
        return reject()

      @downloadVideo(urls)
      .then resolve
      .catch (err)->
        console.log "[!] error while dowloading"
        tools.log err
        reject(err)

  localFileExists: =>
    exists = true
    try
      fs.fs.accessSync(@fname)
    catch
      exists = false
    exists

  downloadVideo: (urls)->
    url = urls.shift()
    new Promise (resolve, reject)=>
      console.log '[+] Downloading video from: ' + url if CONF.debug > 0
      console.log '[+] Saving as ' + @fname if CONF.debug > 0
      file = fs.createOutputStream(@fname)
      start = new Date().getTime()

      fname = path.basename @fname
      request(url: url).on 'response', (response)->
        len = parseInt(response.headers['content-length'], 10)
        bar = new ProgressBar('[o] downloading [:bar] :percent :etas ' + fname,
          complete: '='
          incomplete: ' '
          width: 40
          total: len)
        response.on 'data', (chunk) ->
          bar.tick chunk.length
          return
        #response.on 'end', ->
          #process.stdout.write ' (' + (new Date().getTime() - start) / 1000 + 's)'
        #  return
      .on 'error', (err)->
        console.log  '[!] error while downloading file'
        tools.log err
      .pipe(file)

      file.on 'finish', ->
        #console.log '[+] File downloaded in ' + (new Date().getTime() - start) / 1000 + 's'  if CONF.debug >= 0
        file.close(resolve)

      file.on 'error', (err)->
        console.log '[+] error while writing file ' + @fname
        tools.log err
        fs.unlink(@fname)
        return reject(err)

module.exports = Clip
