angular.module('RAAdmin', ["ngRoute", "RAAdminTemplates", "ngMaterial", 'ngFileUpload'])
  .controller(window.RA.Controllers)
  .directive(window.RA.Directives)
  .service(window.RA.Services)
  .factory(window.RA.Factories)
  .filter(window.RA.Filters)

  .config ["$routeProvider", "$locationProvider", "raAPIProvider"
    ($routeProvider, $locationProvider, apiProvider)->
      api = apiProvider.$get()

      $routeProvider
        .when "/admin",
          templateUrl: '/admin/templates/home.html'
          controller: window.RemoteAcademy.Controllers.HomepageController
          controllerAs: "hc"

        .when "/admin/labs",
          templateUrl: '/admin/templates/lab.html'
          resolve: list: ()-> api.listLabs()
          controller: window.RemoteAcademy.Controllers.LabListController
          controllerAs: "lec"

        .when "/admin/labs/edit/:id",
          templateUrl: '/admin/templates/lab-editor.html'
          resolve: lab: ["$route", ($route)-> api.getRow("labs", $route.current.params.id)]
          controller: window.RemoteAcademy.Controllers.LabEditorController
          controllerAs: "lec"

        .when "/admin/labs/new",
          templateUrl: '/admin/templates/lab-editor.html'
          resolve: lab: ()-> {}
          controller: window.RemoteAcademy.Controllers.LabEditorController
          controllerAs: "lec"

        .when "/admin/labsim",
          templateUrl: '/admin/templates/raletest.html'
          controller: window.RemoteAcademy.Controllers.RaleTestController
          controllerAs: "rtc"

      $locationProvider.html5Mode
        enabled: true
  ]
  .controller "AdminController", ()->
    @base = window.location.origin

    # Bootstrap from embedded server data
    @user = window.rauser

    # Register pages with the navigation
    @links = [
      {href: "/admin", title: "Dashboard"},
      {href: "/admin/labs", title: "Labs"},
      {href: "/admin/labsim", title: "LabBox Simulator"}
    ]
    console.log @links
