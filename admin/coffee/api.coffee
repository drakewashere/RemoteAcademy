# API Service
window.RemoteAcademy.Services.raAPI = ["$http", ($http)->

  # CONFIG
  base = "/admin/api/"

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

  @get = (endpoint, commonName = endpoint, baseURL = base)->
    $http.get("#{baseURL}#{endpoint}?nc=#{Math.random()}")
      .catch(defaultErrorHandler.bind(this, commonName))
      .then(completionHandler.bind(this, commonName))

  @post = (endpoint, data, commonName = endpoint)->
    $http.post("#{base}#{endpoint}", data)
      .catch(defaultErrorHandler.bind(this, commonName))
      .then(completionHandler.bind(this, commonName))

  # API METHODS ============================================================================

  # Userspace
  @getSocketId = ()-> @get "socketauth", "GetSocketID", "/api/"

  # Admin - Specific
  @listLabs = ()-> @get "labs/list", "ListLabs"
  @experimentForLabbox = (id)-> @get "experiments/forlabbox/#{id}", "ExperimentForBox"
  @objectId = ()-> @get "objectid", "GetObjectID"

  # Admin - Generic CRUD
  @getRow = (collection, id)-> @get "crud/get/#{collection}/#{id}", "GetDocument"
  @delete = (collection, id)-> @get "crud/delete/#{collection}/#{id}", "DeleteDocument"
  @insert = (collection, doc)-> @post "crud/insert/#{collection}", doc, "InsertDocument"
  @replace = (collection, doc)-> @post "crud/replace/#{collection}", doc, "ReplaceDocument"

  # Admin - CRUD using Query
  @documentsByIds = (collection, ids, fields)->
    @post "crud/ids/#{collection}?fields=#{JSON.stringify fields}",
      {ids: ids}, "DocumentsByIds"

  @documentsByName = (collection, name, fields)->
    if !name? then return []
    @post "crud/query/#{collection}", {
      query: {"$or": [
        {"name":  {"$regex": name, $options: "i"}},
        {"title": {"$regex": name, $options: "i"}}
      ]},
      fields: fields
    }, "DocumentsByIds"

  return this
]
