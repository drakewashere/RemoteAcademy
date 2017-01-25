# API function that returns an HTML template for a given lab
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"
handlebars = require "handlebars"
html = require "./experiment-templates"

# Used to pass raw data to Angular
handlebars.registerHelper 'json', (context)-> JSON.stringify(context)
handlebars.registerHelper 'ifCond', (v1, v2, options) ->
  if v1 == v2 then return options.fn(this)
  return options.inverse(this)

# Compile all handlebars templates
templates = {}
for name, template of html
  templates[name] = handlebars.compile template

# API method to look up the lab and return an HTML representation of the notebook
module.exports = (id)->
  db = yield database.connect()

  # If the user has an active notebook we grab it to fill in values
  experiments = yield db.queryCollection("experiments", {"_id": ObjectID id}, 2)
  experiment = experiments?[0]
  if !experiment? then return response.error this, 1411, "Experiment does not exist"

  # Render Input Controls
  inputs = []
  for deviceId, spec of experiment.setup
    for ii, input of spec.inputs
      input.experiment = experiment.index
      input.device = deviceId
      inner = templates[input.type] input
      inputs.push templates["_input"] {inner: inner, object: input}

  # Render Output Display
  outputs = for oi, output of experiment.input
    output.experiment = experiment.index
    inner = templates[output.type] output
    templates["_output"] {inner: inner, object: output}

  experimentHTML = templates["_experiment"]
    experiment: experiment
    input: inputs.join ""
    output: outputs.join ""

  this.body = experimentHTML
