# API function that saves one or more fields of a notebook
# Can also be used through websockets
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (labId, notebookUpdate)->
  if !@req.isAuthenticated() then return response.error this, 403, "Not Logged In"

  # For now it's too hard to track their actual completion, so we just track:
  #   0 || undefined = Not Started      0.5 = In Progress      1 = Finished
  notebookUpdate.completion = 0.5

  db = yield database.connect()
  write = yield db.update "notebooks",
    # Find the right notebook
    {
      "user": @req.user["_id"].toString(),
      "lab": labId
    },
    # Update this notebook's values
    {
      "$set": notebookUpdate,
      "$push": {timestamps: new Date().getTime()}
    }

  response.data this, write.result.nModified == 1

  # Returning something makes it easier to use this function from WS
  return write.result.nModified == 1
