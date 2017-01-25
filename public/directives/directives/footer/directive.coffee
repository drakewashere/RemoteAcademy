# Show the full RemoteAcademy footer on landing pages
window.RemoteAcademy.Directives.raFooter = () ->

  # Directive configuration
  restrict: 'E'
  replace: true

  # HTML Template
  template: """
    <table class="footer"><tr>
      <td><a href="/register/class"><b>Add Class</b></a></td>
      <td><a href="/about">About</a></td>
      <td><a href="/legal">Legal</a></td>
      <td><a href="/logout">Logout</a></td>
    </tr></table>
  """
