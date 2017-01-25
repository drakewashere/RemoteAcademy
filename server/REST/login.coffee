module.exports = ()->
  @redirect if @user? then @query.redirect else "/"
  yield return
