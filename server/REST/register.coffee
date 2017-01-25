# API function that registers a user for a section
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (classId, sectionId)->
  if !@req.isAuthenticated() then return response.error this, 403, "Not Logged In"

  db = yield database.connect()
  data = yield db.update("users", {_id: ObjectID(@req.user._id)}, {
    $push: {classes: [classId, sectionId]}
  })

  response.data this, data?
  yield return
