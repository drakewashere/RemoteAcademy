# API function that adds information to a user's account
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = ()->
  if !@req.isAuthenticated() then return response.error this, 403, "Not Logged In"

  db = yield database.connect()
  data = yield db.update("users", {_id: ObjectID(@req.user._id)}, {
    $set: @request.body
  })

  response.data this, data?
  yield return
