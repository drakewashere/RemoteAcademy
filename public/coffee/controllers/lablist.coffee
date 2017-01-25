class window.RemoteAcademy.Controllers.LabListController
  constructor: ($location, $http, raAPI)->
    @$location = $location
    @loading = true
    raAPI.listLabs().then (classes)=>
      @classes = classes
      @loading = false

  open: (labID)->
    @$location.path("/lab/#{labID}")

# Chooses a color based on due date urgency
window.RemoteAcademy.Filters.dueColor = ()-> (date)->
  cDate = new Date().getTime()
  secDiff = Math.round((date - cDate) / 1000)
  hrDiff = secDiff / 3600

  if hrDiff < 4 then return "#FF4949"
  if hrDiff < 24 then return "#FFC659"
  return "#A0D768"


# Make Angular happy even when minified
window.RemoteAcademy.Controllers.LabListController.$inject = ["$location", "$http", "raAPI"]
