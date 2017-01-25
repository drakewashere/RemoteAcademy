# API function that returns an HTML template for a given lab
ObjectID = require('mongodb').ObjectID;
database = require "../database"
response = require "../response"
handlebars = require "handlebars"
html = require "./lab-templates"

# Used to pass raw data to Angular
handlebars.registerHelper 'json', (context)-> JSON.stringify(context)

# Compile all handlebars templates
templates = {}
for name, template of html
  templates[name] = handlebars.compile template

# API method to look up the lab and return an HTML representation of the notebook
module.exports = (id)->

  db = yield database.connect()

  # If the user has an active notebook we grab it to fill in values
  labQuery = db.queryCollection("labs", {"_id": ObjectID(id)}, 2)
  nbQuery =  db.queryCollection("notebooks", {
    "user": @req.user["_id"].toString(),
    "lab": id
  }, 2)

  [list, notebookList] = yield [labQuery, nbQuery]
  notebook = notebookList?[0]

  # If no notebook exists, create one for the user
  if !notebook
    db.insert "notebooks",
      "user": @req.user["_id"].toString()
      "lab": id
      "completion": 0
      "timestamps": []
      "values": []


  if list.length is 0 then return response.error this, 1311, "Lab does not exist"
  if list.length > 1 then return response.error this, 1312, "Database Error: Duplicated ID!"
  lab = list[0]

  html = for si, section of lab.sections
    if section.experiment?
      templates["_experiment"] {section: section}

    else
      sectionValues = notebook?.values?[si]
      inner = for component in section.content
        if v = sectionValues?[component.name] then component.value = v
        templates[component.type] component
      inner = inner.join "\n"
      templates["_section"] {section: section, inner: inner, index: si}

  notebook = html.join "\n"
  this.body = templates["_page"] {notebook: notebook, lab: lab}
