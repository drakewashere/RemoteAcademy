# Renders the RemoteAcademy header with a custom banner
window.RemoteAcademy.Directives.raHeader = () ->

  # Directive configuration
  restrict: 'E'
  replace: true
  scope:
    banner: "@"

  # HTML Template
  template: """
    <header>
      <img src="/img/logo.svg"></img>
      <div class="banner" ng-bind="banner" ng-show="banner"></div>
    </header>
  """
