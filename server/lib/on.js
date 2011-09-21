var events = require('events');

module.exports.inject = function(object) {
  object.emitter = events.EventEmitter();

  object.on = function(key, handler) {
    object.emitter.on(key, handler);
  }

  object.emit = function() {
    object.emitter.emit(arguments);
  }
}
