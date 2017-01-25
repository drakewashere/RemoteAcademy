# THIS CODE IS FOR TESTING PURPOSES ONLY
# It does not need to be in the final build

class window.RemoteAcademy.Controllers.RaleTestController
  constructor: (socket, api)->
    @socket = socket
    socket.connect(((d)-> d), "/rale")
    @api = api;

    @simulating = false
    @collecting = false
    @connected = false

    @sendrate = 100
    @dataCount = 0
    @dataCache = {}


  # EXPERIMENT SETUP =======================================================================

  lookup: (id)->
    @api.experimentForLabbox(id).then (experiment)=>
      if experiment == false
        @hasExperiment = false
      else
        @hasExperiment = true
        @experiment = @formatExperiment(experiment)

  formatExperiment: (experiment)->
    for _, device of experiment.setup
      for output in device.outputs
        output.generation = "random"
        output.period = 10
      for input in device.inputs
        input.value = input.default
    return experiment


  # LB REGISTRATION ========================================================================

  toggleSimulation: (id)=>
    if !@simulating then @startSimulation(id)
    else @stopSimulation()

  startSimulation: (id)=>
    @simulating = true

    @socket.emit "identity", id, (ret)=>
      if ret.success != true then throw new Error "Could not connect"
      @identified = true

    # Read values from input
    @socket.on "control", (data)=>
      try
        device = @experiment.setup[data.device]
        for input in device.inputs when input.id == data.key
          input.value = data.value
      catch
        console.log "Received invalid control (input) signal"

    # Wait for control signals about the data streaming
    @socket.on "status", (status)=>
      if status > 0 then @connected = true
      else @connected = false

      if status == 5 or status == 7
        @startDataStream()
      else
        @stopDataStream()


  stopSimulation: ()=>
    @simulating = false
    @stopDataStream()
    @socket.connect(((d)-> d), "/rale")


  # LB DATA SIMULATION =====================================================================

  startDataStream: ()=>
    @collecting = true
    @generationLoops = []

    # Initialize data sending loop
    @generationLoops.push every @sendrate, @sendData

    # Initialize data collection loops
    for did, device of @experiment.setup
      for output in device.outputs
        start = new Date().getTime()
        @generationLoops.push every output.period, ((o, start)=>
          save = @registerData.bind this, did, o.id
          return ()=>
            elapsed = new Date().getTime() - start

            # Generation Functions
            if o.generation is "random" then save Math.random()
            if o.generation is "sine1000" then save Math.sin(elapsed / 1000)
            if o.generation is "sine100" then save Math.sin(elapsed / 100)
            if o.generation is "set" then save output.set

        )(output, start)

  stopDataStream: ()=>
    if !@collecting then return
    @collecting = false
    for interval in @generationLoops
      clearInterval interval
    @dataCache = {}
    @dataCount = 0

  # Send data to the experiment
  sendData: ()=>
    @socket.emit "data", {index: @dataCount++, data: @dataCache}
    @dataCache = {}


  # Data storage
  registerData: (id, key, value) ->
    if @dataCache[id] is undefined then @dataCache[id] = []
    @dataCache[id].push
      time: new Date().getTime(),
      data: [{key: key, value: value}]


# Make Angular happy even when minified
window.RemoteAcademy.Controllers.RaleTestController.$inject = [
  "socket", "raAPI"
]
