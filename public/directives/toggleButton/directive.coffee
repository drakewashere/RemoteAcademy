# Connect this directive to
window.RemoteAcademy.Directives.toggleButton = () ->

  # Directive configuration
  restrict: 'A'
  scope: {'toggleButton': '&'}

  # Connect everything up
  link: (scope, element, attrs, autosaveSection)->

    # Function to set the button's value
    updateMode = (isOn)->
      scope.buttonOn = isOn
      scope.toggleButton state: isOn

      element[0].innerHTML = if isOn then "On" else "Off"
      if isOn
        element.removeClass "off"
      else
        element.addClass "off"

    updateMode 0

    # Watch for clicks
    element.on "click", ()->
      updateMode if scope.buttonOn is 1 then 0 else 1
