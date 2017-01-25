# API function that replaces a class, experiment, or lab with an updated version
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (collection)->

  # Make sure the user has specified a valid (access controlled) collection
  if collection != "classes" and collection != "labs" and collection != "experiments"
    response.error this, 4410, "Please specify a collection in {classes, labs, experiments}"
    return false

  # Extract the new document
  data = @request.body
  if !data or !data["_id"]
    response.error this, 4416, "Please send a data object with a valid ID"
    return false
  id = data["_id"]
  data["_id"] = ObjectID id

  # Make sure the user has the appropriate access priviledges
  db = yield database.connect()
  query = database.queryWithAccessControls(@req.user, {
    _id: ObjectID(id)
  });

  # Replace the row
  updated = yield db.update(collection, query, data)
  response.data this, updated
  yield return
