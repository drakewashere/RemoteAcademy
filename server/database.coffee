MongoClient = require('mongodb').MongoClient;
Q = require 'q'
config = require '../config'

# Tracks request times
debug = false


# HELPERS ==================================================================================

# Decorates mongo query criteria to fetch only documents the user has access to
# Only used by the admin interface
exports.queryWithAccessControls = (user, otherCriteria)->
  accessQuery = {$or: [
    {"_access.users": {$in: [user.username]}},
    {"_access.groups": {$in: user.adminGroups}}
  ]};

  if !otherCriteria?
    return accessQuery
  else
    return {$and: [accessQuery, otherCriteria]};


# CONNECTION ===============================================================================

connection = undefined

exports.connect = ()-> new Q.Promise (resolve, reject, notify)->

  # If it's already connected, we're good to go
  if connection? then return resolve connection

  # Connect
  console.log "Connecting to Mongo"
  MongoClient.connect config.MONGO_URL, (err, db)->
    if err?
      throw new Error "Could not connect to database"
      reject err
    else
      connection = new exports.DatabaseConnection db
      resolve connection


exports.disconnect = ()->
  if !connection? then return
  connection.close()


# Clean up when we're done
process.on 'SIGTERM', exports.disconnect


# DATABASE CLASS ===========================================================================

class exports.DatabaseConnection
  constructor: (db)->
    @db = db


# SELECT ===================================================================================

  listCollection: (name, fields)-> new Q.Promise (resolve, reject, notify)=>
    @db.collection(name).find({}, fields).toArray (err, documents)->
      if err? then reject(err) else resolve(documents)

  queryCollection: (name, query, limit, fields, sort)->
    if debug then starttime = new Date().getTime()

    new Q.Promise (resolve, reject, notify)=>
      query = @db.collection(name).find(query, fields)
      if limit? then query = query.limit(limit)
      if sort? then query = query.sort(sort)
      query.toArray (err, documents)->
        if debug
          console.log "Query to #{name} took #{new Date().getTime() - starttime}ms"
        if err? then reject(err) else resolve(documents)

  querySubCollection: (collection, unwindField, query, limit, fields, sort, regroup)->
    new Q.Promise (resolve, reject, notify)=>
      aggregation = []

      # Limit the fields first to speed up data processing
      if fields? then aggregation.push { $project: fields }

      # Unwind the data to query children individually
      aggregation.push { $unwind: "$#{unwindField}" }

      # Add other query properties
      if query? then aggregation.push { $match: query }
      if limit? then aggregation.push { $limit: limit }
      if sort? then aggregation.push { $sort: sort }

      # Regroup the data by parent
      if regroup?
        groupAcc = {_id: regroup}
        groupAcc[unwindField] = { $push: "$#{unwindField}" }
        aggregation.push { $group: groupAcc }

      @db.collection(collection).aggregate(aggregation).toArray (err, documents)->
        if err? then reject(err) else resolve(documents)


# INSERT ===================================================================================

  insert: (name, data)-> new Q.Promise (resolve, reject, notify)=>
    @db.collection(name).insertOne data, (err, result)->
      if err isnt null then reject(err)
      else resolve result

  getNextSequence: (name)-> new Q.Promise (resolve, reject, notify)=>
    @db.eval "getNextSequence('#{name}')", (err, result)->
      if err isnt null then reject(err)
      else resolve result


# UPDATE ===================================================================================

  update: (name, query, data, upsert = false)-> new Q.Promise (resolve, reject, notify)=>
    @db.collection(name).updateOne query, data, { upsert: upsert }, (err, result)->
      if err isnt null then reject(err)
      else resolve result


# DELETE ===================================================================================

  delete: (name, query)-> new Q.Promise (resolve, reject, notify)=>
    @db.collection(name).deleteOne query, (err, result)->
      if err isnt null then reject(err)
      else resolve result


# ADVANCED =================================================================================

  aggregate: (name, aggregation)-> new Q.Promise (resolve, reject, notify)=>
    @db.collection(name).aggregate aggregation, (err, result)->
      if err isnt null then reject(err)
      else resolve result
