# Uploads an image to the RA Admin Endpoint
window.RemoteAcademy.Directives.raAdminImageUpload = () ->

  # Directive configuration
  restrict: 'E'
  replace: false
  scope:
    labId: "@"
    link: "="

  # HTML Template
  templateUrl: "/admin/templates/imageUpload/template.html"

  # Controller
  controller: ["$scope", "Upload", "$timeout", ($scope, Upload, $timeout)->

    # Wait for the user to start the upload
    $scope.$watch 'file', ()->
      $scope.upload($scope.file)

    # Using ng-file-upload
    $scope.upload = (file) ->
      if file? and !file.$error
        $scope.uploading = true
        Upload.upload({
          url: "/admin/api/images/upload/#{$scope.labId || 'unknown'}",
          data: {
            file: file
          }
        }).then(((resp)->
          $timeout ()->
            $scope.uploading = false
            $scope.success = resp.status == 200
            $scope.link = resp.data.data
          ), null, ((evt)->
            progressPercentage = parseInt(100.0 *	evt.loaded / evt.total)
          ))
  ]
