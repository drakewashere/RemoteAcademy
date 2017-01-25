# API function that returns the experiment attached to a RPi with a given ID
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (collection, id)->

  # Make sure the user has specified a valid (access controlled) collection
  if collection != "classes" and collection != "labs" and collection != "experiments"
    response.error this, 4710, "Please specify a collection in {classes, labs, experiments}"
    return false

  db = yield database.connect()
  query = database.queryWithAccessControls(@req.user, {
    _id: ObjectID(id)
  });
  list = yield db.queryCollection(collection, query, 2)

  if list.length is 0 then response.data this, false
  else if list.length > 1 then response.error this, 6314, "Database Error: Duplicated ID!"
  else response.data this, list[0]

  yield return
