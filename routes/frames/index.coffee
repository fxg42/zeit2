module.exports = (app, db) ->

  frames = require('./frames')(db)

  app.namespace '/api/frames', ->

    app.get '/', (req, res) ->
      frames.list (err, frames) ->
        res.json frames

    app.get '/:id', (req, res) ->
      frames.get req.params.id, (err, frame) ->
        res.json frame

    app.put '/', (req, res) ->
      frames.update req.body, (err) ->
        res.send(if err then 500 else 201)

    app.post '/', (req, res) ->
      frames.create req.body, (err, _id) ->
        if err
          res.send 500
        else
          res.json {_id}

    app.delete '/:id', (req, res) ->
      frames.delete req.params.id, (err) ->
        res.send 201
