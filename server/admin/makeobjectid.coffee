# The simplest possible thing
ObjectID = require('mongodb').ObjectID;
response = require "../response"

module.exports = (collection)->
  response.data this, ObjectID()
  yield return
