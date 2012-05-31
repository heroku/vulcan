cradle = require("cradle")
url    = require("url")

module.exports.connect = (database, cb) ->

  if parsed = url.parse(process.env.CLOUDANT_URL)
    if parsed.auth
      options =
        auth:
          username: parsed.auth.split(":")[0]
          password: parsed.auth.split(":")[1]
    else
      options = {}
  else
    options = {}

  db = new (cradle.Connection)(parsed.hostname, parsed.port or 5984, options).database(database)
  db.create ->
    cb(db) if cb
  db
