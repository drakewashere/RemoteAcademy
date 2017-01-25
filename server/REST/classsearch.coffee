# API function that looks up classes availavle to the logged in user
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = (query)->
  if !@req.isAuthenticated() then return response.error this, 403, "Not Logged In"
  query = decodeURIComponent query

  db = yield database.connect()
  list = yield db.queryCollection("classes", {
    $and: [
      "domains": @req.user.domain,
      $or: [
        {"sections.id": parseInt query},
        {$text: {$search: "\"" + query + "\"" }}
      ]
    ]
  }, 10, {_id: 1, name: 1, professor: 1, school: 1, sections: 1})
  response.data this, list

  yield return
