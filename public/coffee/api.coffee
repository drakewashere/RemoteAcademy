# API Service
window.RemoteAcademy.Services.raAPI = ["$http", ($http)->

  # CONFIG
  base = "/api/"

  # HELPER METHODS
  defaultErrorHandler = (endpoint, error)->
    console.log "[API: #{endpoint}] Request Failed. ERROR:"
    console.log error

  completionHandler = (endpoint, data)->
    if data.status is 500
      defaultErrorHandler endpoint, "Internal Server Error"
    else if data.status isnt 200
      defaultErrorHandler endpoint, "HTTP Error Code #{data.status}"
    else if !data.data? or data.data is ""
      defaultErrorHandler endpoint, "Received Empty Response"
    else if data.data.error != 0
      defaultErrorHandler endpoint, "Server Error Response: #{data.data.error}"
    else
      # Angular Response Data . Server Response Data . API Return Data
      return data.data.data

  @get = (endpoint, commonName = endpoint)->
    $http.get("#{base}#{endpoint}?nc=#{Math.random()}")
      .catch(defaultErrorHandler.bind(this, commonName))
      .then(completionHandler.bind(this, commonName))

  @post = (endpoint, data, commonName = endpoint)->
    $http.post("#{base}#{endpoint}", data)
      .catch(defaultErrorHandler.bind(this, commonName))
      .then(completionHandler.bind(this, commonName))

  # API METHODS ============================================================================

  # Users
  @updateUser = (fields)-> @post "user/update", fields, "UpdateUser"
  @registerForSection = (cId, sId)-> @get "user/register/#{cId}/#{sId}", "RegisterUser"
  @getSocketId = ()-> @get "socketauth", "GetSocketID"

  # Classes
  @classSearch = (query)-> @get "class/#{encodeURIComponent query}", "ClassSearch"

  # Labs
  @listLabs = ()-> @get "labs/list", "ListLabs"
  @getLab = (id)-> @get "labs/get/#{id}", "GetLab"
  @submitNotebook = (id)-> @get "notebooks/submit/#{id}", "SubmitNotebook"

  # Data
  @getData = (expId, dataId) -> @get "data/#{expId}/#{dataId}", "GetExpData"

  return this

]
