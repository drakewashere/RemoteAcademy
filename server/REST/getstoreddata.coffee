# API function that saves one or more fields of a notebook
# Can also be used through websockets
ObjectID = require('mongodb').ObjectID;
database = require "../database"
datastore = require "../datastore"
response = require "../response"
co = require "co"

module.exports = (experimentId, cacheId)->
  db = yield database.connect()
  list = yield db.queryCollection "experiments", {"_id": ObjectID(experimentId)}, 2,
    {"_id": 0, "rales": 0}

  if list.length is 0 then response.error this, 1311, "Lab does not exist"
  else if list.length > 1 then response.error this, 1312, "Database Error: Duplicated ID!"

  response.data this, datastore.get(cacheId)?.makeCSV(list[0])
  yield return
