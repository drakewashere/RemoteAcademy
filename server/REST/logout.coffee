module.exports = ()->
  @req.logout()
  @redirect("/")
  yield return
