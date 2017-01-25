# Show a different RemoteAcademy footer on the lab page
window.RemoteAcademy.Directives.raAdminLabSectionEditor = () ->

  # Directive configuration
  restrict: 'E'
  replace: false
  scope:
    section: "="
    index: "@"
    labId: "@"

  templateUrl: "/admin/templates/labSectionEditor/lab-section-editor.html"

  # Controller
  controller: ["$scope", ($scope)->

    $scope.add = (type)->
      $scope.section.content.push {
        type: type
      }

    $scope.move_up = (index)->
      if index == 0 then return
      item = $scope.section.content[index]
      $scope.section.content.splice index, 1
      $scope.section.content.splice index - 1, 0, item

    $scope.move_down = (index)->
      if index == $scope.section.content.length - 1 then return
      item = $scope.section.content[index]
      $scope.section.content.splice index, 1
      $scope.section.content.splice index + 1, 0, item

    $scope.delete = (index)->
      if confirm "Are you sure you want to delete this field?"
        $scope.section.content.splice index, 1
  ]
