coffee  = require("coffee-script")
express = require("express")
fs      = require("fs")
logger  = require("logger")
rest    = require("restler")
spawner = require("spawner").init()
url     = require("url")
util    = require("util")
uuid    = require("node-uuid")

db = require("cloudant").connect("make")

app = express.createServer(
  express.logger()
  express.cookieParser()
  express.bodyParser())

app.post "/make", (req, res, next) ->
  id      = uuid()
  command = req.body.command
  prefix  = req.body.prefix
  deps    = if req.body.deps then JSON.parse(req.body.deps) else []
  log     = logger.init(res, next, id)

  unless req.body.secret is process.env.SECRET
    return log.error "invalid secret"

  # return build id as a header
  res.header "X-Make-Id", id

  # keep the response alive
  setInterval (-> res.write(String.fromCharCode(0) + String.fromCharCode(10))), 1000

  # save build to couchdb
  log.info "saving to couchdb"
  db.save id, command:command, prefix:prefix, deps:deps, (err, doc) ->
    return log.error(util.inspect(err)) if err

    save_attachment = (source, cb) ->
      source.pipe(
        db.saveAttachment {id:doc.id, rev:doc.rev}, {name:"input", "Content-Type":"application/octet-stream"}, (err, data) ->
          return log.error(err.reason) if err && err.error != "conflict"
          cb())

    build = ->
      res.write "done\n"
      res.write "Building with: #{command}\n"
      log.info  "spawning build"
      make = spawner.spawn "bin/make \"#{id}\"", env:
        CLOUDANT_URL: process.env.CLOUDANT_URL
        PATH: process.env.PATH
      make.on "error", (err)  -> log.error(err)
      make.on "data",  (data) -> res.write data
      make.on "end",   (code) -> res.end()

    if (req.files.code)
      log.info "saving attachment - [id:#{doc.id} rev:#{doc.rev}]"
      save_attachment fs.createReadStream(req.files.code.path), ->
        build()

    else if (req.body.code_url)
      log.info "downloading attachment: #{req.body.code_url}"
      parts = url.parse(req.body.code_url)
      client = if parts.protocol is "https:" then require("https") else require("http")
      get = client.request parts, (res) ->
        save_attachment res, ->
          build()
      get.end()

app.get "/output/:id", (req, res, next) ->
  log    = logger.init(res, next, req.params.id)
  stream = db.getAttachment req.params.id, "output"
  stream.on "error", (err)   -> log.error(err)
  stream.on "data",  (chunk) -> res.write chunk, "binary"
  stream.on "end",           -> res.end()

app.listen process.env.PORT or 3000
