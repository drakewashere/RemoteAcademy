# API function that returns a list of active labs for a user, paired with their completion
# status for each.

# This is the most complicated query in all of Remote.Academy
# Unfortunately it is also one of the more common ones
# Hopefully Mongo scales *Crosses Fingers*

ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"

module.exports = ()->

  # DATA COLLECTION ========================================================================
  # Pulling from 3 different collections, it's a hell of a thing

  db = yield database.connect()

  # Load all of the user's classes
  classQuery = yield db.queryCollection "classes",

    # Find future labs in classes the user is registered for
    {
      "_id": {"$in": @req.user.classes.map((a)-> ObjectID(a[0]))}
    }, undefined, # Return every matching class

    # Limit return fields (full labs can be quite large)
    {"_id": 1, "name": 1}


  console.log JSON.stringify {
    "$and": [
      {"classes": {"$in": @req.user.classes.map((a)-> a[0])}},
      {"due": {"$gte": new Date().getTime()}}
    ]
  }

  # Load all of the labs for those classes
  labQuery = yield db.queryCollection "labs",

    # Find future labs in classes the user is registered for
    {
      "$and": [
        {"classes": {"$in": @req.user.classes.map((a)-> a[0])}},
        {"due": {"$gte": new Date().getTime()}}
      ]
    }, undefined, # Return every matching lab

    # Limit return fields (full labs can be quite large)
    {"classes.$": 1, "title": 1, "subtitle": 1, "due": 1},

    # Next due date first
    {"labs.due": 1}

  # Run these in parallel
  [classData, labData] = yield [classQuery, labQuery]

  # Now cross-reference this data with the user's notebooks to see where they are
  labIds = []
  labIds.push(l["_id"].toString()) for l in labData
  if !labIds[0] then return response.data this, []

  userData = yield db.queryCollection "notebooks",
    {
      $and: [
          {"user": @req.user["_id"].toString()},
          {"lab": {"$in": labIds}}
      ]
    }, undefined,
    {"lab": 1, "completion": 1}


  # LOCAL DATA PROCESSING ==================================================================
  # Collect these 3 sources into something usable by the client

  # Collate user data into labs
  for notebook in userData
    for labObject in labData
      if JSON.stringify(notebook.lab) is JSON.stringify(labObject["_id"])
        labObject.completion = notebook.completion
        break

  # Group by class
  ret = (
    for classObject in classData
      labs = []
      for labObject in labData when labObject?
        if "\"#{labObject.classes[0]}\"" is JSON.stringify(classObject["_id"])
          labObject.class = undefined
          labs.push labObject
      {name: classObject.name, labs: labs})

  # Finally, send a nice little package back to the client
  response.data this, ret

  yield return
