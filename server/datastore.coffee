# The datastore collects data from LabBoxes as fast as it can and stores it on the server
# until the client is ready to download. Data will only be stored for a certain amount of
# time before it is deleted.

Lifespan = 600000 # 600,000ms = 10 minutes

# Data that exceedes a certain number of rows will be reduced by cutting every-other row.

MaxRows = 10000 # 10,000 rows

# Datastore entries are created with a unique ID

crypto = require 'crypto'
createID = ()-> return crypto.randomBytes(64).toString('hex');

entries = {}
exports.create = ()->
  id = createID()
  entries[id] = new exports.Store(id)
  return entries[id]

exports.get = (id)-> return entries[id]


# Data storage object
class exports.Store
  constructor: (id)->
    @id = id
    @time = new Date().getTime()
    @rows = []

    @killTimer = wait Lifespan, @kill.bind(this)

  kill: ()->
    clearTimeout @killTimer
    @rows = []
    delete entries[@id]

  add: (row)-> # Assume row is of the form LabBoxEntry from spec/data
    if typeof row == "string" then row = JSON.parse row
    if @rows.length is MaxRows then @bicemate()
    @rows.push row

  bicemate: ()->
    @rows = (@rows[i] for i in [0...@rows.length] by 2)


  # CSV export is a little more complicated because it needs knowledge of the experiment
  # to correctly decorate the data.
  makeCSV: (experiment)-> # Of type Experiment from spec/experiment

    # Currently the data is stored as LabBoxEntry rows. It needs to be assembled into
    # key-value pairs grouped by timestamp
    pairsByTimestamp = {}
    for lbe in @rows
      for device, datablocks of lbe.data
        for block in datablocks
          if !pairsByTimestamp[block.time]? then pairsByTimestamp[block.time] = []
          (pair.device = device) for pair in block.data
          Array.prototype.push.apply pairsByTimestamp[block.time], block.data

    # Assemble all key-device pairs to turn them into columns
    columns = {}
    for time, kvps of pairsByTimestamp
      for kvp in kvps
        kvp.colKey = kvp.device + "." + kvp.key
        columns[kvp.colKey] = true

    # Create a header row from column names
    header = ["Elapsed Time (ms)"]
    for name of columns
      header.push name
    rows = [header]

    # Find the lowest timestamp value, to convert all timestamps to relative
    startTime = Math.pow(2, 53) - 1
    for time, _ of pairsByTimestamp
      if time < startTime then startTime = time

    # Assemble full table rows for each timestamp
    for time, kvps of pairsByTimestamp
      row = [time - startTime]
      for colname of columns
        foundEntry = false
        for kvp in kvps when kvp.colKey == colname
          foundEntry = true
          row.push kvp.value
          break
        if !foundEntry then row.push undefined
      rows.push(row)

    # Convert this table into CSV
    CSV = ""
    for row in rows
      formatted = for col in row
        if typeof col == "string" then "\"#{col.replace(/\"/g,"\"\"")}\""
        else col
      CSV = CSV + formatted.join(",") + "\n"

    return CSV
