events = require("events")

module.exports.inject = (object) ->
  object.emitter = events.EventEmitter()

  object.on = (key, handler) ->
    object.emitter.on key, handler

  object.emit = ->
    object.emitter.emit arguments
