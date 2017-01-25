# Connect this directive to
window.RemoteAcademy.Directives.raAutosave = () ->

  # Directive configuration
  restrict: 'A'
  require: '^raAutosaveSection'
  scope: {raAutosave: "&"}

  # Connect everything up
  link: (scope, element, attrs, autosaveSection)->
    element.on "input", ()->
      scope.raAutosave({section: autosaveSection.section, value: @value})

# Empty directive that allows the content to be divided into sections
window.RemoteAcademy.Directives.raAutosaveSection = () ->
  restrict: 'A'
  scope: {raAutosaveSection: "@"}
  controller: ["$scope", ($scope)-> @section = parseInt $scope.raAutosaveSection]
