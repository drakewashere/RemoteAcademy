# API function that returns information about the server
npmdata = require "../../package.json"
response = require "../response"

module.exports = ()->
  response.data this, {
    "domain": "remote.academy",
    "version": npmdata.version
  }

  # Necessary for Koa's generator system
  yield return
