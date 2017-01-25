class window.RemoteAcademy.Controllers.RegisterAccountController
  constructor: ($scope, $location, raAPI)->
    @$location = $location
    @$scope = $scope
    @api = raAPI

    @email = $scope.app.user.username + "@" + $scope.app.user.domain
    @labNotify = true
    @name = ""

  submit: ()->
    @api.updateUser({
      email: @email,
      notifications:
        lab: @labNotify
      fullname: if @name then @name else "Anonymous"
    }).then ()=>

     @$scope.app.user.email = @email
     @$scope.app.user.fullname = if @name isnt "" then @name else undefined
     @$scope.app.user.notifications = {
       lab: @labNotify
     }

     @$location.path('/register/class')


# Make Angular happy even when minified
window.RemoteAcademy.Controllers.RegisterAccountController.$inject = [
  "$scope", "$location", "raAPI"]
