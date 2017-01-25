state = require "../state"
database = require "../database"
datastore = require "../datastore"
co = require 'co'

module.exports = (socket)->
  raleID = undefined

  # STEP 1: Client must identify itself with a unique ID
  isIdentified = false
  socket.emit 'identify', {message: 'Return Lab Box Id'}
  socket.on 'identity', (data,cb)->
    if isIdentified then return socket.emit 'identified', {}
    raleID = data

    # Find the experiment in the database
    co ()->
      db = yield database.connect()
      data = yield db.queryCollection("experiments", {"rales": raleID}, 1)

      # The experiment doesn't exist
      if data.length is 0
        return cb {
          errorCode: 2023, message: "Experiment does not exist"
        }

      # Good to go
      isIdentified = true
      state.addRale raleID, data[0], socket
      cb {success: true}


  # STEP 2: Accept incoming data
  socket.on 'data', (data)->
    if !isIdentified then socket.emit 'identify', {message: 'Return Lab Box Id'}

    # Log this data in the global state
    state.addDataPoint raleID, data


  # STEP 3: Send movie images straight through
  socket.on 'image', (jpegData)->
    if !(clientID = state.getRale(raleID).connected) then return
    client = state.getClient clientID
    if !client.socket? then return
    client.socket.volatile.emit "image", jpegData


  # STEP 4: LabBox disconnects
  socket.on 'disconnect', ()-> state.removeRale(raleID)
