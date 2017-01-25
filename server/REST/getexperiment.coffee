# API function that saves one or more fields of a notebook
# Can also be used through websockets
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"
co = require "co"

module.exports = co.wrap (experimentId)->
  console.log experimentId

  db = yield database.connect()
  list = yield db.queryCollection "experiments", {"_id": ObjectID(experimentId)}, 2,
    {"_id": 0, "rales": 0}

  if list.length is 0 then response.error this, 1311, "Lab does not exist"
  else if list.length > 1 then response.error this, 1312, "Database Error: Duplicated ID!"
  else response.data this, list[0]

  return list[0]
