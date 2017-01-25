# Adds a new object to the database with appropriate access controls
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"
config = require "../../config"

module.exports = (collection)->

  # Make sure the user has specified a valid (access controlled) collection
  if ["classes", "experiments", "labs", "users", "notebooks"].indexOf(collection) == -1
    response.error this, 4511, "Please specify a valid database collection"
    return false

  # Extract the new document
  data = @request.body
  if !data or data["_id"]
    data["_id"] = ObjectID(data["_id"])

  # Create an access control
  data._access = {users: [@req.user.username], groups: [config.DEFAULT_ACCESS_GROUPS]}

  # Replace the row
  db = yield database.connect()
  inserted = yield db.insert(collection, data)
  response.data this, inserted
  yield return
