# Show a different RemoteAcademy footer on the lab page
window.RemoteAcademy.Directives.raAdminDataTable = () ->

  # Directive configuration
  restrict: 'E'
  scope:
    columns: "="
    actions: "="
    data: "="

  # HTML Template
  templateUrl: "/admin/templates/dataTable/template.html"

  # Controller
  controller: ["$scope", ($scope)->

    # This function takes in data and runs any mapping operations required to format
    # the data properly
    process = (data, columns)->
      for row in data
        copyRow = {_id: row._id}
        for column in columns
          if column.map? then copyRow[column.key] = column.map(row[column.key])
          else copyRow[column.key] = row[column.key]
        copyRow

    # Keep the processing up to spec
    $scope._processed = process $scope.data, $scope.columns
    $scope.$watchCollection "data", ()->
      $scope._processed = process $scope.data, $scope.columns

    # Run actions
    $scope.runAction = (actionIndex, rowId)->
      action = $scope.actions[actionIndex]
      if !action? then return alert "Could not perform action"
      if action.confirm
        if confirm("Are you sure you want to perform '#{action.label}' on this row?")
          action.execute(rowId)
      else action.execute(rowId)

  ]
