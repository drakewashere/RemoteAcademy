parse = require 'co-busboy'
path = require 'path'
crypto = require 'crypto'
fs = require 'fs'
response = require "../response"
database = require "../database"

uploadDir = path.resolve path.dirname(__filename, module.uri), "../../public/lab_img"

module.exports = (lab_id)->
  parts = parse this
  part = yield parts

  fileId = crypto.randomBytes(20).toString('hex')
  stream = fs.createWriteStream(path.join(uploadDir, fileId))
  part.pipe(stream)

  # Name the file including the extension
  extension = part.filename.split(".").pop()
  fileName = fileId + "." + extension
  yield new Promise (resolve)->
    fs.rename path.join(uploadDir, fileId), path.join(uploadDir, fileName), resolve


  db = yield database.connect()
  inserted = yield db.insert("images", {
    filename: fileName
    uploaded: new Date().getTime()
    by: @req.user._id
    for: lab_id
  })

  response.data this, "/lab_img/#{fileName}"
  yield return
