state = require "../state"
co = require "co"
savefields = co.wrap(require "../REST/savefields")

module.exports = (socket)->
  clientID = undefined
  collectionTimeout = undefined

  socket.on 'disconnect', (data)-> state.disconnect clientID


  # SECURITY ===============================================================================

  # To start, the client must identify themselves
  isIdentified = false
  socket.emit 'identify', {message: 'Return a ClientID'}
  socket.on 'identity', (id, cb)->
    if isIdentified then return socket.emit 'identified', {}
    isIdentified = true
    clientID = id
    if state.connectClient clientID, socket
      cb undefined
    else
      cb {code: 1016, message: "Invalid ClientID"}


  # NOTEBOOK ===============================================================================

  socket.on 'save', ({lab, update}, cb)->
    context = {
      req: {
        isAuthenticated: ()->true,
        user: {_id: state.getClient(clientID).userid}
      }
    }
    savefields.call(context, lab, update).then cb


  # EXPERIMENT CONTROL =====================================================================

  # The client can attempt to start an experiment. The server checks to see if there are any
  # labboxes available and responds accordingly
  socket.on 'start', (experimentID, cb)->
    if !isIdentified then return socket.emit 'identify', {message: 'Return a ClientID'}

    # Get all RALEs hosting the requested experiment
    rales = state.getRalesForExperiment experimentID
    if rales.length < 1

      # There are no RALEs actively hosting the experiment
      return cb {code: 1023, message: 'Experiment not available'}

    # If a RALE is available, connect to it
    for raleID in rales when state.getRale(raleID).connected is false
      return state.connect raleID, clientID

    # Otherwise, add this client to the queue and send it updates
    state.queue clientID, experimentID


  # Client sends control signals to the experiment
  socket.on 'control', (inputField)->
    raleID = state.getClient(clientID).connected
    if !raleID then return
    rale = state.getRale(raleID)
    if !rale? then return

    {device, key, value} = inputField
    rale.socket.emit 'control', {device, key, value}


  # Disconnect from experiment
  socket.on 'finish', (data, cb)->
    cb state.disconnect clientID


  # EXPERIMENT DATA COLLECTION =============================================================

  # Control data collection
  socket.on 'startCollecting', (duration)->
    raleID = state.getClient(clientID).connected
    if !raleID then return
    state.changeRaleStatus raleID, state.status.collecting

    # Give some extra time for data to come in
    collectionTimeout = wait duration + 100, ()->
      raleDataId = state.getRale(raleID)?.datastore?.id
      state.changeRaleStatus raleID, state.status.connected
      socket.emit 'collected', {cacheID: raleDataId}


  socket.on 'startStreaming', ()->
    raleID = state.getClient(clientID).connected
    if !raleID then return
    state.changeRaleStatus raleID, state.status.streaming


  socket.on 'stopCollecting', ()->
    raleID = state.getClient(clientID).connected
    if !raleID then return
    state.changeRaleStatus raleID, state.status.connected
    clearTimeout collectionTimeout
