# API function that saves one or more fields of a notebook
# Can also be used through websockets
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (labId)->
  if !@req.isAuthenticated() then return response.error this, 403, "Not Logged In"

  db = yield database.connect()
  write = yield db.update "notebooks",
    # Find the right notebook
    {
      "user": @req.user["_id"].toString(),
      "lab": labId
    },
    # Update this notebook's values
    {
      "$set": {completion: 1},
    }

  response.data this, write.result.nModified == 1

  # Returning something makes it easier to use this function from WS
  return write.result.nModified == 1
