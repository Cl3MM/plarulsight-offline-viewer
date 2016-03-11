path   = require 'path'
fs     = require 'fs-extra'
_      = require 'lodash'
secret = require './secret'

argv   = require('yargs')
  .usage('Usage:\n  app.js -u <url>\n  app.js -f <file>')
  .alias('u', 'url')
  .nargs('u', 1)
  .describe('u', 'Pluralsight video player url')
  .alias('f', 'file')
  .nargs('f', 1)
  .describe('f', 'File containing a list of urls')
  .argv

if !argv.f and !argv.u
  console.log "Missing required argument u or f"
  process.exit 0

app       = "https://app.pluralsight.com/"
root_path = path.normalize path.join(__dirname, '../')

urls = []

if argv.f
  content = fs.readFileSync(argv.f, 'utf8')
  urls = _.compact(content.split '\r\n').filter (line)-> !line.startsWith('#')
else
  urls = [argv.url]

module.exports =
  argv            : argv
  debug           : 0
  user            : secret.user
  pass            : secret.pass
  ua              : "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/48.0.2564.116 Safari/537.33"
  urls            : urls
  root            : app + 'id'
  app             : app
  retrieveUrl     : 'player/retrieve-url'
  screenshots_path: path.join(root_path, 'screenshots/')
  lib_path        : path.join(root_path, 'lib/')
  assets_path     : path.join(root_path, 'assets/')
  video_path      : path.join(root_path, 'assets/videos/')
