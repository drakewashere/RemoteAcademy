# API function that returns a list of experiments that the user has admin access to
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = ()->
  db = yield database.connect()
  query = database.queryWithAccessControls(@req.user)
  list = yield db.queryCollection("experiments", query)
  response.data this, list
  yield return
