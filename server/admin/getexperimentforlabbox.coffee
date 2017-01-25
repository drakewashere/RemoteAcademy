# API function that returns the experiment attached to a RPi with a given ID
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (id)->
  db = yield database.connect()
  query = database.queryWithAccessControls(@req.user, {
    rales: {$in: [id]}
  });
  list = yield db.queryCollection("experiments", query, 2)

  if list.length is 0 then response.data this, false
  else if list.length > 1 then response.error this, 6314, "Database Error: Duplicated ID!"
  else response.data this, list[0]

  yield return
