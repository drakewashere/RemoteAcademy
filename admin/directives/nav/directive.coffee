# Sidebar Navigation for Admin
window.RemoteAcademy.Directives.raAdminNav = () ->

  # Directive configuration
  restrict: 'E'
  replace: false
  scope:
    links: "="

  # HTML Template
  template: """
    <header>
      <h2>Remote.Academy</h2>
      <h4>Administration Interface</h4>
    </header>
    <hr/>
    <ul>
      <li   ng-repeat="link in links"
            ng-click="activate(link)"
            ng-class="{active: link.active}">
          {{link.title}}
      </li>
    </ul>
  """

  # Controller
  controller: ["$scope", "$location", ($scope, $location)->

    $scope.$watch "links", ()=>
      if !$scope.links? then return
      for link in $scope.links when $location.url() == link.href
        @activeLink = link
        @activeLink.active = true
        break

    $scope.activate = (link)=>
      $location.url(link.href)
      if @activeLink? then @activeLink.active = false
      link.active = true
      @activeLink = link
  ]
