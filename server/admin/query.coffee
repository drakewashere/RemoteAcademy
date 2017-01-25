# Totally generic endpoint for retrieving data in a Mongo-style format
# Other endpoints are preferred because they allow the frontend to be invariant to database
# structure changes, however we're on a tight timeline and this is clearly easier.
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (collection)->

  # Make sure the user has specified a valid (access controlled) collection
  if collection != "classes" and collection != "labs" and collection != "experiments"
    response.error this, 4710, "Please specify a collection in {classes, labs, experiments}"
    return false

  db = yield database.connect()
  query = database.queryWithAccessControls(@req.user, @request.body.query);
  list = yield db.queryCollection(
    collection, query,
    @request.body.limit, @request.body.fields, @request.body.sort
  )

  response.data this, list
  yield return
