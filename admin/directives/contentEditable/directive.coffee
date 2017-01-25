# Allows ngModel and ngChange to tie in with contenteditable
# Adapted from http://jsfiddle.net/Tentonaxe/V4axn/
window.RemoteAcademy.Directives.contenteditable = ["$parse", ($parse)->

  restrict: 'A'
  require: '?ngModel'

  link: (scope, element, attrs, ngModel)->

    # If there's no ngModel, no override is necessary
    # the browser's implementation will do just fine
    if !ngModel then return

    # Override angular's view rendering
    ngModel.$render = ()-> element.html ngModel.$viewValue || ''

    # Gets the new value from HTML
    read = ()->
      html = element.html()
      html = html.replace("&nbsp;", " ").replace("&amp;", "&")
      ngModel.$setViewValue(html)

    # Set the element's html to the starting value
    element.html $parse(attrs.ngModel)(scope)

    # Watch for user input and run the read function
    element.on 'blur keyup change', ()-> scope.$apply(read)
    read()
]
