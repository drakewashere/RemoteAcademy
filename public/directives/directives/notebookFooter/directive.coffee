# Show a different RemoteAcademy footer on the lab page
window.RemoteAcademy.Directives.raNotebookFooter = () ->

  # Directive configuration
  restrict: 'E'
  replace: true

  scope:
    loading: "="
    status: "="

  # HTML Template
  template: """
    <table class="notebookfooter footer"><tr>
      <td style="width:auto"></td>
      <td><a href="/labs">Back to Labs</a></td>
      <td><a href="/help">Help</a></td>
      <td class="autosave">
        <img src="/img/loader.svg" class="loader" ng-show="loading"/>
        <p ng-hide="loading" ng-bind="status"></p>
      </td>
      <td style="width:auto"></td>
    </tr></table>
  """
