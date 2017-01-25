exports.data = (ctx, data)->
  ctx.body = {error: 0, message: "Success", data: data}

exports.error = (ctx, code, message)->
  console.log "[ERROR #{code}]: #{message}"
  ctx.body = {error: code, message: message, data: {}}
