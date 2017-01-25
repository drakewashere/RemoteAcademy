# Show a different RemoteAcademy footer on the lab page
window.RemoteAcademy.Directives.raDataTable = () ->

  # Directive configuration
  restrict: 'E'
  replace: true
  require: '^raAutosaveSection'
  scope: {raAutosave: "&"}

  scope:
    columns: "@"
    data: "@"
    change: "&"

  # HTML Template
  template: """
    <table class="datatable" cellspacing="0" cellpadding="0">
      <tr class="head">
        <th ng-repeat="column in real_columns"
            ng-bind="column.label" ng-style="{width: column.width}">
        </th>
        <th class="action" ng-click="deleteAll()">&#x2715;</th>
      </tr>
      <tr ng-repeat="row in real_data" ng-show="real_data.length > 0" class="datarow">
        <td ng-repeat="point in row track by $index" ng-bind="point"></td>
        <td class="action" ng-click="delete($index)">&#x2715;</td>
      </tr>
      <tr ng-show="real_data.length == 0">
        <td colspan="{{real_columns.length}}" class="tableEmpty">No Data Yet</td>
      </tr>
    </table>
  """

  # Specialized version of ra-autosave
  link: (scope, element, attrs, autosaveSection)->
    scope.onChange = ()->
      scope.change({section: autosaveSection.section, value: scope.real_data})

  # Controller
  controller: ["$scope", ($scope)->
    try
      $scope.real_data = JSON.parse $scope.data
    catch
      $scope.real_data = []

    $scope.real_columns = JSON.parse $scope.columns

    # Listen for incoming data from the lab controller
    document.addEventListener "experimentData", (e)->
      [input, output] = e.data

      $scope.real_data.push (for column in $scope.real_columns
        if column.input? then input[column.input]
        else if column.output? then output[column.output]
      )

      $scope.onChange()

    # Delete a row
    $scope.delete = (index)->
      $scope.real_data.splice(index, 1)
      $scope.onChange()

    # Clear the data
    $scope.deleteAll = (index)->
      if !confirm "Are you sure you want to clear all data?" then return
      $scope.real_data = []
      $scope.onChange()

  ]
