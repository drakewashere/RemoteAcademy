# API function that returns information about the server
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (id)->

  db = yield database.connect()
  list = yield db.queryCollection("labs", {"_id": ObjectID(id)}, 2)

  if list.length is 0 then response.error this, 1311, "Lab does not exist"
  else if list.length > 1 then response.error this, 1312, "Database Error: Duplicated ID!"
  else response.data this, list[0]

  yield return
