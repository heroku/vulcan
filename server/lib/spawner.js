var events  = require('events');
var https   = require('https');
var net     = require('net');
var qs      = require('querystring');
var restler = require('restler');
var spawn   = require('child_process').spawn;
var tls     = require('tls');

var Spawner = function(env) {

  require('on').inject(this);

  this.env = env || process.env.SPAWN_ENV || 'local';

  var cs = this;

  this.spawn = function(command, callback) {
    var spawner = cs['spawn_' + cs.env];

    if (!spawner) {
      callback('no spawner for env: ' + cs.env);
      return(new events.EventEmitter());
    } else {
      console.log('spawning on %s: %s', cs.env, command);
      return(spawner(command, callback));
    }
  }

  this.spawn_local = function(command, callback) {
    var args = command.match(/("[^"]*"|[^"]+)(\s+|$)/g);
    var command = args.shift().replace(/\s+$/g, '');

    args = args.map(function(arg) {
      return(arg.match(/"?([^"]*)"?/)[1]);
    });

    var proc = spawn(command, args, { env: process.env });
    var emitter = new events.EventEmitter();

    proc.stdout.on('data', function(data) {
      emitter.emit('data', data);
    });

    proc.stderr.on('data', function(data) {
      emitter.emit('data', data);
    });

    proc.on('exit', function(code) {
      emitter.emit('exit', code);
    });

    return(emitter);
  }

  this.spawn_heroku = function(command, callback) {
    var api_key = process.env.HEROKU_API_KEY;
    var app     = process.env.HEROKU_APP;
    var emitter = new events.EventEmitter();

    var auth = new Buffer(':' + api_key).toString('base64');

    restler.post('https://api.heroku.com/apps/' + app + '/ps', {
      headers: {
        'Authorization': auth,
        'Accept': 'application/json',
        'User-Agent': 'heroku-gem/2.5'
      },
      data: {
        attach: true,
        command: command,
        'ps_env[AMAZON_BUCKET]': ''
      },
    }).on('success', function(data) {

      var url = require('url').parse(data.rendezvous_url);
      var rendezvous = new net.Socket();

      rendezvous.connect(url.port, url.hostname, function() {
        rendezvous.write(url.pathname.substring(1) + '\n');
      });

      rendezvous.on('data', function(data) {
        if (data != 'rendezvous\r\n') {
          emitter.emit('data', data);
        }
      });

      rendezvous.on('end', function() {
        emitter.emit('exit', 0);
      });

    }).on('error', function(error) {
      emitter.emit('error', error);
    });

    return(emitter);
  }
}

module.exports.create = function(env) {
  return new Spawner(env);
}
