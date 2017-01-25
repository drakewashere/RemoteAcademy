# It is difficult to authenticate the websocket directly because it's handled by an entirely
# different server. Therefore, we have the user authenticate on this REST endpoint and send
# them back a unique key
state = require "../state"
response = require "../response"

module.exports = (labId, notebookUpdate)->
  if !@req.isAuthenticated() then return response.error this, 403, "Not Logged In"

  id = generateCode()
  state.addClient id, @req.user["_id"]
  response.data this, id

  yield return


crypto = require 'crypto'
generateCode = ()->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c)->
    r = crypto.randomBytes(1)[0]%16|0
    v = if c == 'x' then r else (r&0x3|0x8)
    return v.toString(16)
