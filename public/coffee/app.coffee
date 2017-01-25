angular.module('RAFrontend', ["ngRoute", "ngSanitize", "relativeDate", "RAFrontendTemplates"])
  .controller(window.RA.Controllers)
  .directive(window.RA.Directives)
  .service(window.RA.Services)
  .factory(window.RA.Factories)
  .filter(window.RA.Filters)
  .config ["$routeProvider", "$locationProvider", ($routeProvider, $locationProvider)->

    $routeProvider

      .when "/logout",
        # Kind of a hack, makes the request go to the server
        templateUrl: ()-> location.reload()

      .when "/register/account",
        templateUrl: '/templates/register/account.html'
        controller: window.RemoteAcademy.Controllers.RegisterAccountController
        controllerAs: "rac"

      .when "/register/class",
        templateUrl: '/templates/register/class.html'
        controller: window.RemoteAcademy.Controllers.ClassSearchController
        controllerAs: "csc"

      .when "/labs",
        templateUrl: '/templates/lablist.html'
        controller: window.RemoteAcademy.Controllers.LabListController
        controllerAs: "llc"

      .when "/lab/:id",
        templateUrl: (urlattr)-> "/templates/lab/#{urlattr.id}?nc=#{Math.random()}"
        controller: window.RemoteAcademy.Controllers.LabViewController
        controllerAs: "lc"

      .when "/success",
        templateUrl: '/templates/success.html'

    $locationProvider.html5Mode
      enabled: true,
      requireBase: false # Maybe change this later

  ]
  .controller "AppController", ()->
    @base = window.location.origin

    # Bootstrap from embedded server data
    @user = window.rauser
