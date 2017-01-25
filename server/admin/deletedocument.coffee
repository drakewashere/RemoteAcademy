# API function that deletes a document from the database given appropriate access controls
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (collection, id)->

  # Make sure the user has specified a valid (access controlled) collection
  if collection != "classes" and collection != "labs" and collection != "experiments"
    response.error this, 4710, "Please specify a collection in {classes, labs, experiments}"
    return false

  # Make sure the user has the appropriate access priviledges
  db = yield database.connect()
  query = database.queryWithAccessControls(@req.user, {
    _id: ObjectID(id)
  });

  # Replace the row
  deleted = yield db.delete(collection, query)
  response.data this, deleted
  yield return
