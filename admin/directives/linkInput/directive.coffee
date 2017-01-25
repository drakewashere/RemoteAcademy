# Show a different RemoteAcademy footer on the lab page
window.RemoteAcademy.Directives.raAdminLinkInput = () ->

  # Directive configuration
  restrict: 'E'
  scope:
    collection: "@"
    message: "@"
    title: "@"
    ids: "="

  # HTML Template
  templateUrl: '/admin/templates/linkInput/template.html'

  # Controller
  controller: ["$scope", "raAPI", "$mdDialog", ($scope, api, $mdDialog)->

    # Looks up items given their ID
    lookup = (ids)=>
      if !ids? or ids.length == 0 then return $scope.links = []
      api.documentsByIds($scope.collection, ids, {name: 1, title: 1, _id: 1}).then (data)=>
        $scope.links = data

    # Open the adder dialog
    $scope.add = ($event)->
      dlgScope = $scope.$new()

      $mdDialog.show
        controller: AddDialogController,
        controllerAs: 'dlg',
        scope: dlgScope,
        templateUrl: '/admin/templates/linkInput/add-link-dialog.html',
        parent: angular.element(document.body),
        targetEvent: $event,
        clickOutsideToClose: true
      .finally ()=>
        id = dlgScope.addItemId
        if !id? then return
        $scope.ids.push id
        lookup $scope.ids

    # Remove a row
    $scope.delete = (index)->
      if confirm "Are you sure you want to delete this link?"
        $scope.ids.splice index, 1

    # Keep the processing up to spec
    lookup $scope.ids
    $scope.$watchCollection "ids", ()->
      lookup $scope.ids

  ]


# Add Dialog
class AddDialogController
  constructor: ($scope, api, $mdDialog)->
    @message = $scope.message

    # Dialog Control
    @cancel = ($event) -> $mdDialog.cancel()
    @finish = ($event) ->
      $scope.addItemId = @selectedItem?._id
      $mdDialog.hide(@selectedItem._id)

    # Search for documents by name
    @search = (name)->
      api.documentsByName($scope.collection, name, {name: 1, title: 1, _id: 1})

AddDialogController.$inject = ["$scope", "raAPI", "$mdDialog"]
