# Accordion control built around <md-list>
window.RemoteAcademy.Directives.raAdminAccordion = () ->

  # Directive configuration
  restrict: 'E'
  transclude: true
  replace: true
  scope:
    openIndex: "@"
    hasHeader: "@"
    headerTitle: "@"
    headerActions: "="

  # HTML Template
  template: """
    <md-list>
      <md-subheader class="md-no-sticky" ng-show="{{hasHeader}}">
        <div layout-gt-sm="row" layout-align="center center">
          <p>{{headerTitle}}</p>
          <span flex></span>
          <md-button ng-repeat="(ai, action) in headerActions"
            aria-label="{{action.label}}" class="md-secondary"
            ng-click="perform(ai)">
            <md-icon md-icon-set="material-icons">{{action.icon}}</md-icon> {{action.label}}
          </md-button>
        </div>
      </md-subheader>
      <ng-transclude></ng-transclude>
    </md-list>
  """

  # Controller
  controller: ["$scope", "$timeout", ($scope, $timeout)->

    # Accordion Control

    if !$scope.openIndex? then $scope.openIndex = 0

    @items = []

    @addItem = (i)=>
      @items.push i
      if @items.length - 1 is $scope.openIndex
        $timeout (()->i.opened = true), 10
      return @items.length - 1

    @open = (index)=>
      @items[$scope.openIndex].opened = false
      $scope.openIndex = index
      @items[$scope.openIndex].opened = true

    # Actions

    $scope.perform = (actionIndex)->
      $scope.headerActions?[actionIndex]?.execute()

    return this

  ]


# Individual item in the accordion
window.RemoteAcademy.Directives.raAdminAccordionItem = () ->

  # Directive configuration
  restrict: 'E'
  transclude: true
  require: '^raAdminAccordion',
  replace: true
  scope:
    name: "="
    index: "@"
    actions: "="

  # HTML Template
  template: """
    <div ng-click="open()" class="accordionListItem">
      <md-list-item ng-class="{open: opened}">
        <md-icon md-icon-set="material-icons" class="arrow">
          {{opened ? "keyboard_arrow_down" : "keyboard_arrow_right"}}
        </md-icon>
        <p contenteditable ng-model="name"></p>
        <div class="md-secondary action-controls">
          <md-button ng-repeat="(ai, action) in actions"
              aria-label="{{action.label}}" class="md-icon-button"
              ng-click="perform($event, ai)">
            <md-icon md-icon-set="material-icons">{{action.icon}}</md-icon>
          </md-button>
        </div>
      </md-list-item>
      <div class="outer" ng-show="_animOpened" ng-style="{height: height + 'px'}">
        <div class="inner">
          <ng-transclude></ng-transclude>
        </div>
      </div>
    </div>
  """

  # Tie this to the larger accordion control
  link: (scope, elem, attr, accordion) ->
    scope.opened = false
    index = accordion.addItem scope
    scope.open = accordion.open.bind(this, index)

    # Grab the inner element so its height can be measured
    scope.inner = elem[0].querySelector ".inner"


  # Controller
  controller: ["$scope", "$timeout", ($scope, $timeout)->
    $scope.height = 0
    $scope._animOpened = false

    $scope.$watch "opened", (val, oldVal)=>
      if val and !oldVal then @open()
      if oldVal and !val then @close()

    @open = ()->
      $scope._animOpened = true
      $timeout (()->
        $scope.height = $scope.inner.offsetHeight
      ), 5

    @close = ()->
      $scope.height = 0
      $timeout (()->
        $scope._animOpened = false
      ), 200

    # Watch for height change
    $scope.$watch (()=>$scope.inner.offsetHeight), ()=>
      if $scope._animOpened then $scope.height = $scope.inner.offsetHeight

    # Actions

    $scope.perform = (event, actionIndex)->
      $scope.actions?[actionIndex]?.execute(event, parseInt $scope.index)

  ]
