# Remove document access from a new user or group
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (id, type, name)->

  # Make sure the user has specified a valid (access controlled) collection
  if type != "user" and type != "group"
    response.error this, 4610, "Type should be either 'user' or 'group'"
    return false

  # Make sure the user has the appropriate access priviledges
  db = yield database.connect()
  query = database.queryWithAccessControls(@req.user, {
    _id: MongoID(id)
  });

  # Update the document
  push = {}
  push["_access.#{type}"] = name
  updated = yield db.update(collection, query, {$pull: push})
  response.data this, updated
  yield return
