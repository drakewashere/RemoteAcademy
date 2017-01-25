class window.RemoteAcademy.Controllers.LabViewController
  constructor: ($routeParams, $rootScope, $scope, $location, raAPI, socket)->
    @$scope = $scope
    @$location = $location
    @api = raAPI
    @lab = $routeParams.id
    @socket = socket
    @clientID = $scope.app.user.id

    @autosaveLoading = true
    @autosaveStatus = "Loading"
    @experiment = {}
    @activeExperiment = false

    @update = {}
    @debounce = 1000
    @hasSaved = false

    # Set up a thing to prevent the user from navigating away
    @onRouteChangeOff = $rootScope.$on '$locationChangeStart', @routeChange.bind this

    @socket.connect (success, error)=>
      if !success then return alert "Received WS Error. Try refreshing the page. '#{error}'"
      @autosaveLoading = false
      @autosaveStatus = "Autosave Ready"


  # EXPERIMENT CONTROL =====================================================================

  # Use the WS connection to start the experiment
  startExperiment: (experimentID)->

    if @experiment[experimentID]?
      @socket.emit "finish", true, (success)=>
        @activeExperiment = false
        delete @experiment[experimentID]
      return

    @experiment[experimentID] =
      status: "Connecting to Experiment"
      failed: false
      waiting: true
      connected: false

    # Request access to the experiment
    @socket.emit "start", experimentID, (failure)=>
      if failure?.code is 1023
        @experiment[experimentID] =
          status: "There are no LabBoxes online"
          failed: true
          waiting: false

    # Move in the queue
    @socket.on "queueProgress", ({experiment, position})=>
      @experiment[experimentID] =
        status: if position is 1
            "Next in Queue"
          else
            "Number #{position} in Queue"
        failed: false
        waiting: true

    # Connected
    @socket.once "connected", (data)=>
      new Audio('/img/Boop.mp3').play();

      @timeout = data.timeout
      @experimentID = experimentID
      @experiment[experimentID] =
        status: "Finish Experiment"
        failed: false
        waiting: false
        connected: true
        templateUrl: "/templates/experiment/#{experimentID}"
        setup: data.experiment.setup

      @setupExperiment experimentID


  # Experiment Control
  setupExperiment: (experimentID)->
    @activeExperiment = experimentID

    @socket.on "image", (jpegData)->
      frame = "data:image/jpeg;base64," + jpegData
      element = document.getElementById "frame-#{experimentID}"
      element.setAttribute "src", frame

    @lastSample = 0
    @socket.on "data", (data)=>
      alert "CURRENTLY UNSUPPORTED"

  manualSample: ()-> @lastSample = new Date().getTime + 100000 # Hack to override rate

  # End the experiment
  endExperiment: ()->
    @socket.emit "disconnect", {}


  # EXPERIMENT INTERACTION =================================================================

  # Toggle data streaming
  toggleStreaming: ()->
    if @collecting
      @socket.emit "stopCollecting", {}
    else
      @socket.emit "startStreaming", {}
    @collecting = !@collecting

  # Trigger data collection
  triggerCollection: (experimentID, time)->
    @socket.emit "startCollecting", time
    @collecting = true

    @socket.once "collected", (ret)=>
      @collecting = false
      @api.getData(experimentID, ret.cacheID).then (data)=>
        link = document.createElement("a");
        link.setAttribute("href", 'data:text/csv;base64,' + btoa(data););
        link.setAttribute("download", "collected_data.csv");
        link.click();

  # Emit control signals back to the pi
  updateInput: (device, id, value)->
    value = parseInt value

    # Match this with the experiment
    console.log @experiment, @activeExperiment, device, id
    inputs = @experiment[@activeExperiment]?.setup?[device]?.inputs
    if !inputs then return
    for ti in inputs when ti.id is id
      input = ti
    if !input then return alert "[ERROR] Misconfigured input: #{id}"

    # Send it off
    input.value = value
    if input.map? then value = new Function('x', "return " + input.map)(value)
    send = {device: device, key: id, value: value}
    @socket.emit "control", send


  # AUTOSAVE ===============================================================================

  # Save an individual field over the WebSocket
  saveSection: (section, name, value)->
    if @hasSaved then @autosaveStatus = "Recently Saved"
    @update["values.#{section}.#{name}"] = value

    if @lastTimeout? then clearTimeout @lastTimeout
    @lastTimeout = wait @debounce, ()=>
      @$scope.$apply ()=> @autosaveStatus = "Saving Changes..."
      @socket.emit "save", {lab: @lab, update: @update}, (result)=>
        if result
          @autosaveStatus = "All Changes Saved"
          @update = {}
          @hasSaved = true
        else
          @autosaveStatus = "Save Failed!"

  routeChange: ()->
    if JSON.stringify(@update) != "{}"
      @socket.emit "save", {lab: @lab, update: @update}
    @onRouteChangeOff()

  submitNotebook: ()->
    @routeChange()
    @api.submitNotebook(@lab).then ()=>
      @$location.path "/success"


# Make Angular happy even when minified
window.RemoteAcademy.Controllers.LabViewController.$inject = [
  "$routeParams", "$rootScope", "$scope", "$location", "raAPI", "socket"
]

# Custom Event Class
class ExperimentDataEvent
  constructor: (data)->
    evt = new CustomEvent "experimentData"
    evt.data = data
    return evt
