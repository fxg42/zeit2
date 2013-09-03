_       = require 'underscore'
async   = require 'async'
mongodb = require 'mongodb'

oid = (id) -> new mongodb.ObjectID String id

getCollection = (db, name, callback) ->
  db.collection name, {safe:yes}, callback

getProfile = (user, callback, {collection}) ->
  collection.findOne {user}, callback

getFrame = (user, id, callback, {collection}) ->
  query = { user, 'frames._id': oid(id) }
  collection.findOne query, {'frames.$':1}, callback

unshiftFrame = (user, frame, callback, {collection}) ->
  collection.update {user}, {$set:{'frames.-1':frame}}, callback

updateFrame = (user, frame, callback, {collection}) ->
  frame._id = oid frame._id
  query = { user, 'frames._id': frame._id }
  update = { $set: { 'frames.$': frame } }
  collection.update query, update, callback

deleteFrame = (user, id, callback, {collection}) ->
  collection.update {user}, { $pull: {frames: {_id: oid(id)}} }, callback

module.exports = (db) ->
  user = 'default'

  list: (callback) ->
    tasks =
      collection: async.apply getCollection, db, 'frames'
      profile: ['collection', (async.apply getProfile, user)]
    async.auto tasks, (err, {profile}) ->
      callback err, profile.frames

  get: (id, callback) ->
    tasks =
      collection: async.apply getCollection, db, 'frames'
      profile: ['collection', (async.apply getFrame, user, id)]
    async.auto tasks, (err, {profile}) ->
      callback err, profile?.frames[0]

  update: (frame, callback) ->
    tasks =
      collection: async.apply getCollection, db, 'frames'
      update: ['collection', (async.apply updateFrame, user, frame)]
    async.auto tasks, (err) ->
      callback err

  create: (frame, callback) ->
    frame._id = new mongodb.ObjectID
    tasks =
      collection: async.apply getCollection, db, 'frames'
      create: ['collection', (async.apply unshiftFrame, user, frame)]
    async.auto tasks, (err, {list}) ->
      callback err, frame._id

  delete: (id, callback) ->
    tasks =
      collection: async.apply getCollection, db, 'frames'
      delete: ['collection', (async.apply deleteFrame, user, id)]
    async.auto tasks, (err) ->
      callback err


