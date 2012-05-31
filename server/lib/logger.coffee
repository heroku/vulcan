class Logger

  constructor: (@response, @next, @id) ->

  info: (subject) ->
    console.log "[#{@id}] #{subject}"

  error: (subject) ->
    console.log "[#{@id}] ERROR: #{subject}"
    if @next
      @next(subject)
    else
      @response.write(subject)
      @response.send(500)

module.exports.init = (response, next, id) ->
  new Logger(response, next, id)
