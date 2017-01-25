# This app keeps some data locally in RAM. Not only does this help performance, it is
# necessary for the WebSocket connections. This does make it fairly difficult to scale, but
# for the purposes of a small academic project that seems like a reasonable tradeoff.
# If you're the one tasked with fixing that problem, I wish you luck.

datastore = require "./datastore"

# Stores IDs and states of RALE devices communicating with this server
# {id: {
#   id: string,
#   status: number,
#   connected: ClientID || false,
#   timeout: number,                    # How many seconds can clients connect
#   experimentID: number,
#   socket: object,
#   datastore: datastore.Store
# }}
# RALE Status) 0: Nothing     1: Client Connected (Video + Input)     2 : Collecting Data
rales = {}

# Only a certain amount of data can be stored
raleDataLimit = 100

# Stores IDs and socket connections for clients communicating with this server
# {id: {
#   userid: string,                     # Mongo User ID tied to the socket
#   timestamp: number,                  # IDs expire after a time (10 minutes?)
#   socket: object,
#   connected: RaleID || false
# }}
clients = {}

# Stores a queue of clients waiting for connection to an experiment
queue = {}


# INTERNAL STATUS INTERFACE =================================================================

state = module.exports = {

  status: {
    nothing: 0,     #000
    connected: 1,   #001
    collecting: 5,  #101
    streaming: 7    #111
  }

  # RALE MANAGEMENT =========================================================================
  # Stores and manages connected RALE devices

  # Register a RALE with its experiment
  addRale: (id, experiment, socket)->
    rales[id] =
      id: id
      experimentID: experiment._id.toString()
      timeout: experiment.timeout
      socket: socket
      status: 0
      connected: false
      data: []

  getRale: (id)-> rales[id]

  removeRale: (id)->
    if !(rale = rales[id])? then return
    if rale.connected then state.disconnect rale.connected
    delete rales[id]

  getRalesForExperiment: (experimentID)->
    return (id for id, rale of rales when rale.experimentID is experimentID)

  # Alert the RALE when its status changes
  changeRaleStatus: (raleID, newStatus)->
    if rales[raleID] is null then return

    # Create a place for the data to go, if necessary
    if newStatus == state.status.collecting
      rales[raleID].datastore = datastore.create();

    rales[raleID].status = newStatus
    rales[raleID].lastChange = new Date().getTime()
    rales[raleID].socket.emit "status", newStatus


  # CLIENT MANAGEMENT =======================================================================
  # Stores and manages connected clients and their associated user accounts

  # Created by the getsocketid API endpoint. Creates an authenticated user entry
  addClient: (id, userid)->
    clients[id] = {id: id, userid: userid, timestamp: new Date().getTime()}

  # Adds a socket to an authenticated user entry
  connectClient: (id, socket)->
    client = clients[id]
    if !client? or client?.socket? then return false
    if client.timestamp < new Date().getTime() - 1000 * 60 * 10 # 10 minute timeout
      delete clients[id]
      return false

    client.socket = socket
    return true

  getClient: (id)-> clients[id]

  # Add the client to the line for an experiment RALE
  queue: (clientID, experimentID)->
    if !queue[experimentID] then queue[experimentID] = []
    queue[experimentID].push clientID
    clients[clientID].socket.emit "queueProgress",
      experiment: experimentID
      position: queue[experimentID].length


  # EXPERIMENT CONTROL ======================================================================
  # Channels data between the client and the RALE

  # Connect a client to a lab box running an experiment
  connect: (raleID, clientID)->
    if rales[raleID] is null or clients[clientID] is null then return
    client = clients[clientID]
    rale = rales[raleID]

    rale.connected = clientID
    client.connected = raleID
    state.changeRaleStatus raleID, state.status.connected

    # Send a message to the client, if it has an open socket
    timeout = rale.timeout
    if client.socket?
      require("./REST/getexperiment")(rale.experimentID).then (data)->
        client.socket.emit "connected",
          experiment: data
          timeout: timeout

    # Enforce a timeout
    client.expire = wait timeout * 1000, ()-> state.disconnect(clientID)

  # Disconnect a client from its lab box
  disconnect: (clientID)->
    if !(client = clients[clientID])? then return false
    if !client.connected then return false

    raleID = client.connected
    rale = rales[raleID]
    if !rale then return false
    rale.connected = false
    state.changeRaleStatus raleID, rale.status.nothing
    rale.status = 0

    client.connected = false
    clearTimeout(client.expire)

    # Advance the queue
    experimentID = rale.experimentID
    if queue[experimentID]? and queue[experimentID].length > 0
      nextClientID = queue[experimentID].shift()
      state.connect rale.id, nextClientID

      # Notify every client remaining in the queue
      for i, clientID of queue[experimentID] when clients[clientID].socket?
        clients[clientID].socket.emit "queueProgress",
          experiment: experimentID
          position: i + 1

    return true

  # Lab Box -> Client or Data Cache
  addDataPoint: (raleID, point)->
    if (rale = rales[raleID]) is undefined then return false

    if rale.status == state.status.collecting
      rale.datastore.add point

    else if rale.status == state.status.streaming
      # Tell the client about this new data point
      if rale.connected? and client = clients[rale.connected]
        if !client.socket? then return
        client.socket.emit "data", point

}
