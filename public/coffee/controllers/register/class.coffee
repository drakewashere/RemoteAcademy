class window.RemoteAcademy.Controllers.ClassSearchController
  constructor: ($scope, $location, raAPI)->
    @$location = $location
    @api = raAPI

    # Current State
    @loading = false
    @empty = false
    @classes = []
    @selected = -1

    # Watch for the search query to change
    $scope.$watch "rac.query", (newval)=>
      if !newval? or newval is "" then return
      @loading = true
      @classes = []
      @api.classSearch(newval).then (classes)=>
        @loading = false
        @empty = classes.length is 0
        @classes = classes

  select: (classObject, section)->

    # Quick and dirty user confirmation
    if !confirm """
      Are you sure you want to sign up for:
        "#{classObject.name}" with #{classObject.professor}
        #{section.name} (#{section.timeslot})
    """
      return

    # Call the API method
    @api.registerForSection(classObject["_id"], section.id).then (success)=>
      if success
        @$location.path("/labs")
      else
        alert "An unknown error occurred, please contact your professor or TA"


# Make Angular happy even when minified
window.RemoteAcademy.Controllers.ClassSearchController.$inject = [
  "$scope", "$location", "raAPI"]
