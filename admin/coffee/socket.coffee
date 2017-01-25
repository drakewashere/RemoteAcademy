window.RemoteAcademy.Factories.socket = ["$rootScope", "raAPI", ($rootScope, raAPI)->
  socket = undefined
  loaded = false
  return {

    # Connect to the socket using authentication
    connect: (callback, channel = "/client")->
      if loaded then socket.disconnect()

      if window.location.origin.indexOf("localhost") is -1
        origin = "sockets.remote.academy:8000"
      else
        origin = window.location.origin

      socket = io.connect(origin+channel, {transports:['websocket']})
      socket.on "failed", (err)-> callback false, err

      raAPI.getSocketId().then (id)->
        socket.emit "identity", id, (error)->
          if !error?
            loaded = true
            $rootScope.$apply ()-> callback true
          else
            $rootScope.$apply ()-> callback false, error.message


    on: (eventName, callback)->
      socket.on eventName, (data)->
        args = arguments
        $rootScope.$apply ()-> callback.apply(socket, args)

    once: (eventName, callback)->
      socket.once eventName, (data)->
        args = arguments
        $rootScope.$apply ()-> callback.apply(socket, args)

    emit: (eventName, data, callback)->
      socket.emit eventName, data, ()->
        args = arguments
        $rootScope.$apply ()->
          if callback? then callback.apply(socket, args)
  }
]
