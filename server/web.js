require.paths.unshift(__dirname + '/lib');

var cradle  = require('cradle');
var express = require('express');
var fs      = require('fs');
var spawner = require('spawner').create();
var sys     = require('sys');
var uuid    = require('node-uuid');

var app = express.createServer(
  express.logger(),
  express.cookieParser(),
  express.session({ secret: process.env.SECRET }),
  require('connect-form')({ keepExtensions: true })
);

// connect to couchdb
var couchdb_url = require('url').parse(process.env.CLOUDANT_URL);
var couchdb_options = couchdb_url.auth ?
  { auth: { username: couchdb_url.auth.split(':')[0], password: couchdb_url.auth.split(':')[1] }  } :
  { }
var db = new(cradle.Connection)(couchdb_url.hostname, couchdb_url.port || 5984, couchdb_options).database('make');
db.create();

// POST /make starts a build
app.post('/make', function(request, response, next) {

  // require a form
  if (! request.form) {
    response.write('invalid form');
    response.send(500);
  } else {

    // form handler
    request.form.complete(function(err, fields, files) {

      // if there's an error
      if (err) {

        // pass through to the next handler
        next(err);

      } else {

        // match on the shared secret
        if (fields.secret != process.env.SECRET) {
          response.write('invalid secret');
          response.send(500);
        } else {

          var id      = uuid();
          var command = fields.command;
          var prefix  = fields.prefix;

          // create a couchdb documents for this build
          var doc = db.save(id, { command:command, prefix:prefix }, function(err, doc) {

            // save the input tarball as an attachment
            db.saveAttachment(
              doc.id,
              doc.rev,
              'input',
              'application/octet-stream',
              fs.createReadStream(files.code.path),
              function(err, data) {

                // spawn bin/make with this build id
                var ls = spawner.spawn('bin/make ' + id, function(err) {
                  response.write('could not spawn: ' + err);
                  response.send(500);
                });

                ls.on('error', function(error) {
                  response.write('error: ' + err);
                  response.send(500);
                });

                ls.on('data', function(data) {
                  response.write(data);
                });

                ls.on('exit', function(code) {
                  response.end();
                });
              }
            );

            // return the build id as a header
            response.header('X-Make-Id', id);
          });
        }
      }
    });
  }
});

// download build output
app.get('/output/:id', function(request, response, next) {

  // from couchdb
  var stream = db.getAttachment(request.params.id, 'output');

  stream.on('data', function(chunk) {
    response.write(chunk, 'binary');
  });

  stream.on('end', function(chunk) {
    response.end();
  });

});

// start up the webserver
var port = process.env.PORT || 3000;
console.log('listening on port ' + port);
app.listen(port);
