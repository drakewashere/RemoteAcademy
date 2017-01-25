# API function that returns the experiment attached to a RPi with a given ID
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (collection)->

  # Make sure the user has specified a valid (access controlled) collection
  if collection != "classes" and collection != "labs" and collection != "experiments"
    response.error this, 4910, "Please specify a collection in {classes, labs, experiments}"
    return false

  # Make sure the user has sent IDs
  if !@request.body.ids or @request.body.ids.length == 0
    response.error this, 4915, "Please specify one or more IDs"
    return false

  db = yield database.connect()
  query = database.queryWithAccessControls(@req.user, {
    _id: {$in: (ObjectID(id) for id in @request.body.ids)}
  });
  fields = JSON.parse @request.query.fields
  list = yield db.queryCollection(collection, query, undefined, fields)

  response.data this, list
  yield return
