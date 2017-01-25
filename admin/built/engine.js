
/*
 _____               _         _____           _
| __  |___ _____ ___| |_ ___  |  _  |___ ___ _| |___ _____ _ _
|    -| -_|     | . |  _| -_|_|     |  _| .'| . | -_|     | | |
|__|__|___|_|_|_|___|_| |___|_|__|__|___|__,|___|___|_|_|_|_  |
========================================================= |___|
REMOTE.ACADEMY JAVASCRIPT ADMIN INTERFACE
---------------------------------------------------------
 */
var AddDialogController,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

window.RemoteAcademy = window.RA = {
  Controllers: {},
  Directives: {},
  Services: {},
  Factories: {},
  Filters: {
    "firstname": function() {
      return function(str) {
        return str.split(" ")[0];
      };
    }
  }
};

window.wait = function(d, f) {
  return setTimeout(f, d);
};

window.every = function(d, f) {
  return setInterval(f, d);
};

window.RemoteAcademy.Services.raAPI = [
  "$http", function($http) {
    var base, completionHandler, defaultErrorHandler;
    base = "/admin/api/";
    defaultErrorHandler = function(endpoint, error) {
      console.log("[API: " + endpoint + "] Request Failed. ERROR:");
      return console.log(error);
    };
    completionHandler = function(endpoint, data) {
      if (data.status === 500) {
        return defaultErrorHandler(endpoint, "Internal Server Error");
      } else if (data.status !== 200) {
        return defaultErrorHandler(endpoint, "HTTP Error Code " + data.status);
      } else if ((data.data == null) || data.data === "") {
        return defaultErrorHandler(endpoint, "Received Empty Response");
      } else if (data.data.error !== 0) {
        return defaultErrorHandler(endpoint, "Server Error Response: " + data.data.error);
      } else {
        return data.data.data;
      }
    };
    this.get = function(endpoint, commonName, baseURL) {
      if (commonName == null) {
        commonName = endpoint;
      }
      if (baseURL == null) {
        baseURL = base;
      }
      return $http.get("" + baseURL + endpoint + "?nc=" + (Math.random()))["catch"](defaultErrorHandler.bind(this, commonName)).then(completionHandler.bind(this, commonName));
    };
    this.post = function(endpoint, data, commonName) {
      if (commonName == null) {
        commonName = endpoint;
      }
      return $http.post("" + base + endpoint, data)["catch"](defaultErrorHandler.bind(this, commonName)).then(completionHandler.bind(this, commonName));
    };
    this.getSocketId = function() {
      return this.get("socketauth", "GetSocketID", "/api/");
    };
    this.listLabs = function() {
      return this.get("labs/list", "ListLabs");
    };
    this.experimentForLabbox = function(id) {
      return this.get("experiments/forlabbox/" + id, "ExperimentForBox");
    };
    this.objectId = function() {
      return this.get("objectid", "GetObjectID");
    };
    this.getRow = function(collection, id) {
      return this.get("crud/get/" + collection + "/" + id, "GetDocument");
    };
    this["delete"] = function(collection, id) {
      return this.get("crud/delete/" + collection + "/" + id, "DeleteDocument");
    };
    this.insert = function(collection, doc) {
      return this.post("crud/insert/" + collection, doc, "InsertDocument");
    };
    this.replace = function(collection, doc) {
      return this.post("crud/replace/" + collection, doc, "ReplaceDocument");
    };
    this.documentsByIds = function(collection, ids, fields) {
      return this.post("crud/ids/" + collection + "?fields=" + (JSON.stringify(fields)), {
        ids: ids
      }, "DocumentsByIds");
    };
    this.documentsByName = function(collection, name, fields) {
      if (name == null) {
        return [];
      }
      return this.post("crud/query/" + collection, {
        query: {
          "$or": [
            {
              "name": {
                "$regex": name,
                $options: "i"
              }
            }, {
              "title": {
                "$regex": name,
                $options: "i"
              }
            }
          ]
        },
        fields: fields
      }, "DocumentsByIds");
    };
    return this;
  }
];

window.RemoteAcademy.Factories.socket = [
  "$rootScope", "raAPI", function($rootScope, raAPI) {
    var loaded, socket;
    socket = void 0;
    loaded = false;
    return {
      connect: function(callback, channel) {
        var origin;
        if (channel == null) {
          channel = "/client";
        }
        if (loaded) {
          socket.disconnect();
        }
        if (window.location.origin.indexOf("localhost") === -1) {
          origin = "sockets.remote.academy:8000";
        } else {
          origin = window.location.origin;
        }
        socket = io.connect(origin + channel, {
          transports: ['websocket']
        });
        socket.on("failed", function(err) {
          return callback(false, err);
        });
        return raAPI.getSocketId().then(function(id) {
          return socket.emit("identity", id, function(error) {
            if (error == null) {
              loaded = true;
              return $rootScope.$apply(function() {
                return callback(true);
              });
            } else {
              return $rootScope.$apply(function() {
                return callback(false, error.message);
              });
            }
          });
        });
      },
      on: function(eventName, callback) {
        return socket.on(eventName, function(data) {
          var args;
          args = arguments;
          return $rootScope.$apply(function() {
            return callback.apply(socket, args);
          });
        });
      },
      once: function(eventName, callback) {
        return socket.once(eventName, function(data) {
          var args;
          args = arguments;
          return $rootScope.$apply(function() {
            return callback.apply(socket, args);
          });
        });
      },
      emit: function(eventName, data, callback) {
        return socket.emit(eventName, data, function() {
          var args;
          args = arguments;
          return $rootScope.$apply(function() {
            if (callback != null) {
              return callback.apply(socket, args);
            }
          });
        });
      }
    };
  }
];

window.RemoteAcademy.Directives.raAdminAccordion = function() {
  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    scope: {
      openIndex: "@",
      hasHeader: "@",
      headerTitle: "@",
      headerActions: "="
    },
    template: "<md-list>\n  <md-subheader class=\"md-no-sticky\" ng-show=\"{{hasHeader}}\">\n    <div layout-gt-sm=\"row\" layout-align=\"center center\">\n      <p>{{headerTitle}}</p>\n      <span flex></span>\n      <md-button ng-repeat=\"(ai, action) in headerActions\"\n        aria-label=\"{{action.label}}\" class=\"md-secondary\"\n        ng-click=\"perform(ai)\">\n        <md-icon md-icon-set=\"material-icons\">{{action.icon}}</md-icon> {{action.label}}\n      </md-button>\n    </div>\n  </md-subheader>\n  <ng-transclude></ng-transclude>\n</md-list>",
    controller: [
      "$scope", "$timeout", function($scope, $timeout) {
        if ($scope.openIndex == null) {
          $scope.openIndex = 0;
        }
        this.items = [];
        this.addItem = (function(_this) {
          return function(i) {
            _this.items.push(i);
            if (_this.items.length - 1 === $scope.openIndex) {
              $timeout((function() {
                return i.opened = true;
              }), 10);
            }
            return _this.items.length - 1;
          };
        })(this);
        this.open = (function(_this) {
          return function(index) {
            _this.items[$scope.openIndex].opened = false;
            $scope.openIndex = index;
            return _this.items[$scope.openIndex].opened = true;
          };
        })(this);
        $scope.perform = function(actionIndex) {
          var ref, ref1;
          return (ref = $scope.headerActions) != null ? (ref1 = ref[actionIndex]) != null ? ref1.execute() : void 0 : void 0;
        };
        return this;
      }
    ]
  };
};

window.RemoteAcademy.Directives.raAdminAccordionItem = function() {
  return {
    restrict: 'E',
    transclude: true,
    require: '^raAdminAccordion',
    replace: true,
    scope: {
      name: "=",
      index: "@",
      actions: "="
    },
    template: "<div ng-click=\"open()\" class=\"accordionListItem\">\n  <md-list-item ng-class=\"{open: opened}\">\n    <md-icon md-icon-set=\"material-icons\" class=\"arrow\">\n      {{opened ? \"keyboard_arrow_down\" : \"keyboard_arrow_right\"}}\n    </md-icon>\n    <p contenteditable ng-model=\"name\"></p>\n    <div class=\"md-secondary action-controls\">\n      <md-button ng-repeat=\"(ai, action) in actions\"\n          aria-label=\"{{action.label}}\" class=\"md-icon-button\"\n          ng-click=\"perform($event, ai)\">\n        <md-icon md-icon-set=\"material-icons\">{{action.icon}}</md-icon>\n      </md-button>\n    </div>\n  </md-list-item>\n  <div class=\"outer\" ng-show=\"_animOpened\" ng-style=\"{height: height + 'px'}\">\n    <div class=\"inner\">\n      <ng-transclude></ng-transclude>\n    </div>\n  </div>\n</div>",
    link: function(scope, elem, attr, accordion) {
      var index;
      scope.opened = false;
      index = accordion.addItem(scope);
      scope.open = accordion.open.bind(this, index);
      return scope.inner = elem[0].querySelector(".inner");
    },
    controller: [
      "$scope", "$timeout", function($scope, $timeout) {
        $scope.height = 0;
        $scope._animOpened = false;
        $scope.$watch("opened", (function(_this) {
          return function(val, oldVal) {
            if (val && !oldVal) {
              _this.open();
            }
            if (oldVal && !val) {
              return _this.close();
            }
          };
        })(this));
        this.open = function() {
          $scope._animOpened = true;
          return $timeout((function() {
            return $scope.height = $scope.inner.offsetHeight;
          }), 5);
        };
        this.close = function() {
          $scope.height = 0;
          return $timeout((function() {
            return $scope._animOpened = false;
          }), 200);
        };
        $scope.$watch(((function(_this) {
          return function() {
            return $scope.inner.offsetHeight;
          };
        })(this)), (function(_this) {
          return function() {
            if ($scope._animOpened) {
              return $scope.height = $scope.inner.offsetHeight;
            }
          };
        })(this));
        return $scope.perform = function(event, actionIndex) {
          var ref, ref1;
          return (ref = $scope.actions) != null ? (ref1 = ref[actionIndex]) != null ? ref1.execute(event, parseInt($scope.index)) : void 0 : void 0;
        };
      }
    ]
  };
};

window.RemoteAcademy.Directives.contenteditable = [
  "$parse", function($parse) {
    return {
      restrict: 'A',
      require: '?ngModel',
      link: function(scope, element, attrs, ngModel) {
        var read;
        if (!ngModel) {
          return;
        }
        ngModel.$render = function() {
          return element.html(ngModel.$viewValue || '');
        };
        read = function() {
          var html;
          html = element.html();
          html = html.replace("&nbsp;", " ").replace("&amp;", "&");
          return ngModel.$setViewValue(html);
        };
        element.html($parse(attrs.ngModel)(scope));
        element.on('blur keyup change', function() {
          return scope.$apply(read);
        });
        return read();
      }
    };
  }
];

window.RemoteAcademy.Directives.raAdminDataTable = function() {
  return {
    restrict: 'E',
    scope: {
      columns: "=",
      actions: "=",
      data: "="
    },
    templateUrl: "/admin/templates/dataTable/template.html",
    controller: [
      "$scope", function($scope) {
        var process;
        process = function(data, columns) {
          var column, copyRow, j, k, len, len1, results, row;
          results = [];
          for (j = 0, len = data.length; j < len; j++) {
            row = data[j];
            copyRow = {
              _id: row._id
            };
            for (k = 0, len1 = columns.length; k < len1; k++) {
              column = columns[k];
              if (column.map != null) {
                copyRow[column.key] = column.map(row[column.key]);
              } else {
                copyRow[column.key] = row[column.key];
              }
            }
            results.push(copyRow);
          }
          return results;
        };
        $scope._processed = process($scope.data, $scope.columns);
        $scope.$watchCollection("data", function() {
          return $scope._processed = process($scope.data, $scope.columns);
        });
        return $scope.runAction = function(actionIndex, rowId) {
          var action;
          action = $scope.actions[actionIndex];
          if (action == null) {
            return alert("Could not perform action");
          }
          if (action.confirm) {
            if (confirm("Are you sure you want to perform '" + action.label + "' on this row?")) {
              return action.execute(rowId);
            }
          } else {
            return action.execute(rowId);
          }
        };
      }
    ]
  };
};

window.RemoteAcademy.Directives.raAdminImageUpload = function() {
  return {
    restrict: 'E',
    replace: false,
    scope: {
      labId: "@",
      link: "="
    },
    templateUrl: "/admin/templates/imageUpload/template.html",
    controller: [
      "$scope", "Upload", "$timeout", function($scope, Upload, $timeout) {
        $scope.$watch('file', function() {
          return $scope.upload($scope.file);
        });
        return $scope.upload = function(file) {
          if ((file != null) && !file.$error) {
            $scope.uploading = true;
            return Upload.upload({
              url: "/admin/api/images/upload/" + ($scope.labId || 'unknown'),
              data: {
                file: file
              }
            }).then((function(resp) {
              return $timeout(function() {
                $scope.uploading = false;
                $scope.success = resp.status === 200;
                return $scope.link = resp.data.data;
              });
            }), null, (function(evt) {
              var progressPercentage;
              return progressPercentage = parseInt(100.0 * evt.loaded / evt.total);
            }));
          }
        };
      }
    ]
  };
};

window.RemoteAcademy.Directives.raAdminLabSectionEditor = function() {
  return {
    restrict: 'E',
    replace: false,
    scope: {
      section: "=",
      index: "@",
      labId: "@"
    },
    templateUrl: "/admin/templates/labSectionEditor/lab-section-editor.html",
    controller: [
      "$scope", function($scope) {
        $scope.add = function(type) {
          return $scope.section.content.push({
            type: type
          });
        };
        $scope.move_up = function(index) {
          var item;
          if (index === 0) {
            return;
          }
          item = $scope.section.content[index];
          $scope.section.content.splice(index, 1);
          return $scope.section.content.splice(index - 1, 0, item);
        };
        $scope.move_down = function(index) {
          var item;
          if (index === $scope.section.content.length - 1) {
            return;
          }
          item = $scope.section.content[index];
          $scope.section.content.splice(index, 1);
          return $scope.section.content.splice(index + 1, 0, item);
        };
        return $scope["delete"] = function(index) {
          if (confirm("Are you sure you want to delete this field?")) {
            return $scope.section.content.splice(index, 1);
          }
        };
      }
    ]
  };
};

window.RemoteAcademy.Directives.raAdminLinkInput = function() {
  return {
    restrict: 'E',
    scope: {
      collection: "@",
      message: "@",
      title: "@",
      ids: "="
    },
    templateUrl: '/admin/templates/linkInput/template.html',
    controller: [
      "$scope", "raAPI", "$mdDialog", function($scope, api, $mdDialog) {
        var lookup;
        lookup = (function(_this) {
          return function(ids) {
            if ((ids == null) || ids.length === 0) {
              return $scope.links = [];
            }
            return api.documentsByIds($scope.collection, ids, {
              name: 1,
              title: 1,
              _id: 1
            }).then(function(data) {
              return $scope.links = data;
            });
          };
        })(this);
        $scope.add = function($event) {
          var dlgScope;
          dlgScope = $scope.$new();
          return $mdDialog.show({
            controller: AddDialogController,
            controllerAs: 'dlg',
            scope: dlgScope,
            templateUrl: '/admin/templates/linkInput/add-link-dialog.html',
            parent: angular.element(document.body),
            targetEvent: $event,
            clickOutsideToClose: true
          })["finally"]((function(_this) {
            return function() {
              var id;
              id = dlgScope.addItemId;
              if (id == null) {
                return;
              }
              $scope.ids.push(id);
              return lookup($scope.ids);
            };
          })(this));
        };
        $scope["delete"] = function(index) {
          if (confirm("Are you sure you want to delete this link?")) {
            return $scope.ids.splice(index, 1);
          }
        };
        lookup($scope.ids);
        return $scope.$watchCollection("ids", function() {
          return lookup($scope.ids);
        });
      }
    ]
  };
};

AddDialogController = (function() {
  function AddDialogController($scope, api, $mdDialog) {
    this.message = $scope.message;
    this.cancel = function($event) {
      return $mdDialog.cancel();
    };
    this.finish = function($event) {
      var ref;
      $scope.addItemId = (ref = this.selectedItem) != null ? ref._id : void 0;
      return $mdDialog.hide(this.selectedItem._id);
    };
    this.search = function(name) {
      return api.documentsByName($scope.collection, name, {
        name: 1,
        title: 1,
        _id: 1
      });
    };
  }

  return AddDialogController;

})();

AddDialogController.$inject = ["$scope", "raAPI", "$mdDialog"];

window.RemoteAcademy.Directives.raAdminNav = function() {
  return {
    restrict: 'E',
    replace: false,
    scope: {
      links: "="
    },
    template: "<header>\n  <h2>Remote.Academy</h2>\n  <h4>Administration Interface</h4>\n</header>\n<hr/>\n<ul>\n  <li   ng-repeat=\"link in links\"\n        ng-click=\"activate(link)\"\n        ng-class=\"{active: link.active}\">\n      {{link.title}}\n  </li>\n</ul>",
    controller: [
      "$scope", "$location", function($scope, $location) {
        $scope.$watch("links", (function(_this) {
          return function() {
            var j, len, link, ref, results;
            if ($scope.links == null) {
              return;
            }
            ref = $scope.links;
            results = [];
            for (j = 0, len = ref.length; j < len; j++) {
              link = ref[j];
              if (!($location.url() === link.href)) {
                continue;
              }
              _this.activeLink = link;
              _this.activeLink.active = true;
              break;
            }
            return results;
          };
        })(this));
        return $scope.activate = (function(_this) {
          return function(link) {
            $location.url(link.href);
            if (_this.activeLink != null) {
              _this.activeLink.active = false;
            }
            link.active = true;
            return _this.activeLink = link;
          };
        })(this);
      }
    ]
  };
};

window.RemoteAcademy.Controllers.HomepageController = (function() {
  function HomepageController() {
    console.log("welcome home");
  }

  return HomepageController;

})();

window.RemoteAcademy.Controllers.LabEditorController = (function() {
  function LabEditorController(lab, api, $routeParams, $timeout, $mdDialog) {
    var date, i, k1159;
    this.lab = lab;
    this.newLab = false;
    if ((lab == null) || (lab._id == null)) {
      this.newLab = true;
      this.lab = {
        classes: [],
        sections: []
      };
      date = new Date();
      date.setHours(23);
      date.setMinutes(59);
      date.setSeconds(59);
      date.setMilliseconds(0);
      this.lab.due = date.getTime() + 7 * 24 * 60 * 60 * 1000;
      api.objectId().then((function(_this) {
        return function(id) {
          return _this.lab._id = id;
        };
      })(this));
    }
    k1159 = 24 * 60 * 60 * 1000 - 1000;
    this.dayrange = (function() {
      var j, results;
      results = [];
      for (i = j = 0; j <= 31; i = ++j) {
        results.push(i);
      }
      return results;
    })();
    this.times = [
      {
        value: 0,
        name: "Midnight"
      }, {
        value: 1 * 60 * 60 * 1000,
        name: "1am"
      }, {
        value: 2 * 60 * 60 * 1000,
        name: "2am"
      }, {
        value: 3 * 60 * 60 * 1000,
        name: "3am"
      }, {
        value: 4 * 60 * 60 * 1000,
        name: "4am"
      }, {
        value: 5 * 60 * 60 * 1000,
        name: "5am"
      }, {
        value: 6 * 60 * 60 * 1000,
        name: "6am"
      }, {
        value: 7 * 60 * 60 * 1000,
        name: "7am"
      }, {
        value: 8 * 60 * 60 * 1000,
        name: "8am"
      }, {
        value: 9 * 60 * 60 * 1000,
        name: "9am"
      }, {
        value: 10 * 60 * 60 * 1000,
        name: "10am"
      }, {
        value: 11 * 60 * 60 * 1000,
        name: "11am"
      }, {
        value: 12 * 60 * 60 * 1000,
        name: "Noon"
      }, {
        value: 13 * 60 * 60 * 1000,
        name: "1pm"
      }, {
        value: 14 * 60 * 60 * 1000,
        name: "2pm"
      }, {
        value: 15 * 60 * 60 * 1000,
        name: "3pm"
      }, {
        value: 16 * 60 * 60 * 1000,
        name: "4pm"
      }, {
        value: 17 * 60 * 60 * 1000,
        name: "5pm"
      }, {
        value: 18 * 60 * 60 * 1000,
        name: "6pm"
      }, {
        value: 19 * 60 * 60 * 1000,
        name: "7pm"
      }, {
        value: 20 * 60 * 60 * 1000,
        name: "8pm"
      }, {
        value: 21 * 60 * 60 * 1000,
        name: "9pm"
      }, {
        value: 22 * 60 * 60 * 1000,
        name: "10pm"
      }, {
        value: 23 * 60 * 60 * 1000,
        name: "11pm"
      }, {
        value: k1159,
        name: "11:59pm"
      }
    ];
    this.updateTimestamp = (function(_this) {
      return function() {
        date = new Date(_this.due.year, _this.due.month - 1, _this.due.day);
        return _this.lab.due = date.getTime() + parseInt(_this.due.time);
      };
    })(this);
    this.updatePicker = (function(_this) {
      return function(timestamp) {
        date = new Date();
        date.setTime(timestamp);
        return _this.due = {
          time: ((date.getHours() * 60 + date.getMinutes()) * 60 + date.getSeconds()) * 1000,
          day: date.getDate(),
          month: date.getMonth() + 1,
          year: date.getFullYear()
        };
      };
    })(this);
    this.updatePicker(this.lab.due);
    this.sectionHeaderActions = [
      {
        label: "Add Section",
        icon: "add",
        execute: (function(_this) {
          return function() {
            var sectionNamePrompt;
            sectionNamePrompt = $mdDialog.prompt().title('New Section Name').placeholder('Introduction').ariaLabel('Section Name').ok('Create Section').cancel('Cancel');
            return $mdDialog.show(sectionNamePrompt).then(function(result) {
              return _this.lab.sections.push({
                name: result,
                content: []
              });
            });
          };
        })(this)
      }
    ];
    this.sectionActions = [
      {
        label: "Move Section Up",
        icon: "arrow_upward",
        execute: (function(_this) {
          return function($event, index) {
            var section;
            if (index === 0) {
              return alert("Cannot move top section up");
            }
            section = _this.lab.sections[index];
            _this.lab.sections.splice(index, 1);
            return _this.lab.sections.splice(index - 1, 0, section);
          };
        })(this)
      }, {
        label: "Move Section Down",
        icon: "arrow_downward",
        execute: (function(_this) {
          return function($event, index) {
            var section;
            if (index === _this.lab.sections.length - 1) {
              return alert("Cannot move bottom section down");
            }
            section = _this.lab.sections[index];
            _this.lab.sections.splice(index, 1);
            return _this.lab.sections.splice(index + 1, 0, section);
          };
        })(this)
      }, {
        label: "Delete Section",
        icon: "delete_sweep",
        execute: (function(_this) {
          return function($event, index) {
            if (confirm("Are you sure you want to delete this section?")) {
              return _this.lab.sections.splice(index, 1);
            }
          };
        })(this)
      }
    ];
    this.saving = false;
    this.saveChanges = function() {
      this.saving = true;
      if (this.newLab) {
        return api.insert("labs", this.lab).then((function(_this) {
          return function() {
            return $timeout((function() {
              _this.saving = false;
              return _this.newLab = false;
            }), 500);
          };
        })(this), (function(_this) {
          return function() {
            return alert("Could not create lab! Check your internet connection and try again");
          };
        })(this));
      } else {
        return api.replace("labs", this.lab).then((function(_this) {
          return function() {
            return $timeout((function() {
              return _this.saving = false;
            }), 500);
          };
        })(this), (function(_this) {
          return function() {
            return alert("Could not save lab! Check your internet connection and try again");
          };
        })(this));
      }
    };
    this.deleteLab = function() {
      if (confirm("Are you sure you want to delete this lab?")) {
        return api["delete"]("labs", this.lab._id).then((function(_this) {
          return function(d) {
            if (d.ok === 1) {
              return window.location = "/admin/labs";
            } else {
              return alert("Could not delete lab. Server returned an error!");
            }
          };
        })(this));
      }
    };
  }

  return LabEditorController;

})();

window.RemoteAcademy.Controllers.LabEditorController.$inject = ["lab", "raAPI", "$routeParams", "$timeout", "$mdDialog"];

window.RemoteAcademy.Controllers.LabListController = (function() {
  function LabListController(list, api, $location) {
    this.data = list;
    this.columns = [
      {
        label: "Title",
        key: "title"
      }, {
        label: "Subtitle",
        key: "subtitle"
      }, {
        label: "Due",
        key: "due",
        map: function(t) {
          return new Date(t).toLocaleString();
        }
      }, {
        label: "Classes",
        key: "classes",
        map: function(t) {
          return t.length;
        }
      }
    ];
    this.actions = [
      {
        label: "Delete",
        icon: "delete forever",
        execute: (function(_this) {
          return function(id) {
            return _this["delete"](id);
          };
        })(this),
        confirm: true
      }, {
        label: "Duplicate",
        icon: "content_copy",
        execute: (function(_this) {
          return function(id) {
            return _this.duplicate(id);
          };
        })(this),
        confirm: true
      }, {
        label: "Edit",
        icon: "edit",
        execute: (function(_this) {
          return function(id) {
            return _this.edit(id);
          };
        })(this)
      }
    ];
    this.newLab = function() {
      return $location.url('/admin/labs/new');
    };
    this.reload = function() {
      return api.listLabs().then((function(_this) {
        return function(labs) {
          return _this.data = labs;
        };
      })(this));
    };
    this["delete"] = function(id) {
      return api["delete"]("labs", id).then((function(_this) {
        return function(d) {
          var index, ref, results, row;
          if (d.ok === 1) {
            ref = _this.data;
            results = [];
            for (index in ref) {
              row = ref[index];
              if (row._id === id) {
                results.push(_this.data.splice(index, 1));
              }
            }
            return results;
          } else {
            return alert("Could not delete row. Server returned an error!");
          }
        };
      })(this));
    };
    this.duplicate = function(id) {
      var newObj, obj, row;
      obj = ((function() {
        var j, len, ref, results;
        ref = this.data;
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          row = ref[j];
          if (row._id === id) {
            results.push(row);
          }
        }
        return results;
      }).call(this))[0];
      if (obj == null) {
        return alert("Could not find entry to duplicate");
      }
      newObj = angular.copy(obj);
      newObj.title = newObj.title + " (copy)";
      delete newObj._id;
      return api.insert("labs", newObj).then((function(_this) {
        return function(d) {
          if (d.ok === 1) {
            return _this.reload();
          } else {
            return alert("Could not duplicate row. Server returned an error!");
          }
        };
      })(this));
    };
    this.edit = function(id) {
      return $location.url("/admin/labs/edit/" + id);
    };
  }

  return LabListController;

})();

window.RemoteAcademy.Controllers.LabListController.$inject = ["list", "raAPI", "$location"];

window.RemoteAcademy.Controllers.RaleTestController = (function() {
  function RaleTestController(socket, api) {
    this.sendData = bind(this.sendData, this);
    this.stopDataStream = bind(this.stopDataStream, this);
    this.startDataStream = bind(this.startDataStream, this);
    this.stopSimulation = bind(this.stopSimulation, this);
    this.startSimulation = bind(this.startSimulation, this);
    this.toggleSimulation = bind(this.toggleSimulation, this);
    this.socket = socket;
    socket.connect((function(d) {
      return d;
    }), "/rale");
    this.api = api;
    this.simulating = false;
    this.collecting = false;
    this.connected = false;
    this.sendrate = 100;
    this.dataCount = 0;
    this.dataCache = {};
  }

  RaleTestController.prototype.lookup = function(id) {
    return this.api.experimentForLabbox(id).then((function(_this) {
      return function(experiment) {
        if (experiment === false) {
          return _this.hasExperiment = false;
        } else {
          _this.hasExperiment = true;
          return _this.experiment = _this.formatExperiment(experiment);
        }
      };
    })(this));
  };

  RaleTestController.prototype.formatExperiment = function(experiment) {
    var _, device, input, j, k, len, len1, output, ref, ref1, ref2;
    ref = experiment.setup;
    for (_ in ref) {
      device = ref[_];
      ref1 = device.outputs;
      for (j = 0, len = ref1.length; j < len; j++) {
        output = ref1[j];
        output.generation = "random";
        output.period = 10;
      }
      ref2 = device.inputs;
      for (k = 0, len1 = ref2.length; k < len1; k++) {
        input = ref2[k];
        input.value = input["default"];
      }
    }
    return experiment;
  };

  RaleTestController.prototype.toggleSimulation = function(id) {
    if (!this.simulating) {
      return this.startSimulation(id);
    } else {
      return this.stopSimulation();
    }
  };

  RaleTestController.prototype.startSimulation = function(id) {
    this.simulating = true;
    this.socket.emit("identity", id, (function(_this) {
      return function(ret) {
        if (ret.success !== true) {
          throw new Error("Could not connect");
        }
        return _this.identified = true;
      };
    })(this));
    this.socket.on("control", (function(_this) {
      return function(data) {
        var device, error1, input, j, len, ref, results;
        try {
          device = _this.experiment.setup[data.device];
          ref = device.inputs;
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            input = ref[j];
            if (input.id === data.key) {
              results.push(input.value = data.value);
            }
          }
          return results;
        } catch (error1) {
          return console.log("Received invalid control (input) signal");
        }
      };
    })(this));
    return this.socket.on("status", (function(_this) {
      return function(status) {
        if (status > 0) {
          _this.connected = true;
        } else {
          _this.connected = false;
        }
        if (status === 5 || status === 7) {
          return _this.startDataStream();
        } else {
          return _this.stopDataStream();
        }
      };
    })(this));
  };

  RaleTestController.prototype.stopSimulation = function() {
    this.simulating = false;
    this.stopDataStream();
    return this.socket.connect((function(d) {
      return d;
    }), "/rale");
  };

  RaleTestController.prototype.startDataStream = function() {
    var device, did, output, ref, results, start;
    this.collecting = true;
    this.generationLoops = [];
    this.generationLoops.push(every(this.sendrate, this.sendData));
    ref = this.experiment.setup;
    results = [];
    for (did in ref) {
      device = ref[did];
      results.push((function() {
        var j, len, ref1, results1;
        ref1 = device.outputs;
        results1 = [];
        for (j = 0, len = ref1.length; j < len; j++) {
          output = ref1[j];
          start = new Date().getTime();
          results1.push(this.generationLoops.push(every(output.period, ((function(_this) {
            return function(o, start) {
              var save;
              save = _this.registerData.bind(_this, did, o.id);
              return function() {
                var elapsed;
                elapsed = new Date().getTime() - start;
                if (o.generation === "random") {
                  save(Math.random());
                }
                if (o.generation === "sine1000") {
                  save(Math.sin(elapsed / 1000));
                }
                if (o.generation === "sine100") {
                  save(Math.sin(elapsed / 100));
                }
                if (o.generation === "set") {
                  return save(output.set);
                }
              };
            };
          })(this))(output, start))));
        }
        return results1;
      }).call(this));
    }
    return results;
  };

  RaleTestController.prototype.stopDataStream = function() {
    var interval, j, len, ref;
    if (!this.collecting) {
      return;
    }
    this.collecting = false;
    ref = this.generationLoops;
    for (j = 0, len = ref.length; j < len; j++) {
      interval = ref[j];
      clearInterval(interval);
    }
    this.dataCache = {};
    return this.dataCount = 0;
  };

  RaleTestController.prototype.sendData = function() {
    this.socket.emit("data", {
      index: this.dataCount++,
      data: this.dataCache
    });
    return this.dataCache = {};
  };

  RaleTestController.prototype.registerData = function(id, key, value) {
    if (this.dataCache[id] === void 0) {
      this.dataCache[id] = [];
    }
    return this.dataCache[id].push({
      time: new Date().getTime(),
      data: [
        {
          key: key,
          value: value
        }
      ]
    });
  };

  return RaleTestController;

})();

window.RemoteAcademy.Controllers.RaleTestController.$inject = ["socket", "raAPI"];

angular.module('RAAdmin', ["ngRoute", "RAAdminTemplates", "ngMaterial", 'ngFileUpload']).controller(window.RA.Controllers).directive(window.RA.Directives).service(window.RA.Services).factory(window.RA.Factories).filter(window.RA.Filters).config([
  "$routeProvider", "$locationProvider", "raAPIProvider", function($routeProvider, $locationProvider, apiProvider) {
    var api;
    api = apiProvider.$get();
    $routeProvider.when("/admin", {
      templateUrl: '/admin/templates/home.html',
      controller: window.RemoteAcademy.Controllers.HomepageController,
      controllerAs: "hc"
    }).when("/admin/labs", {
      templateUrl: '/admin/templates/lab.html',
      resolve: {
        list: function() {
          return api.listLabs();
        }
      },
      controller: window.RemoteAcademy.Controllers.LabListController,
      controllerAs: "lec"
    }).when("/admin/labs/edit/:id", {
      templateUrl: '/admin/templates/lab-editor.html',
      resolve: {
        lab: [
          "$route", function($route) {
            return api.getRow("labs", $route.current.params.id);
          }
        ]
      },
      controller: window.RemoteAcademy.Controllers.LabEditorController,
      controllerAs: "lec"
    }).when("/admin/labs/new", {
      templateUrl: '/admin/templates/lab-editor.html',
      resolve: {
        lab: function() {
          return {};
        }
      },
      controller: window.RemoteAcademy.Controllers.LabEditorController,
      controllerAs: "lec"
    }).when("/admin/labsim", {
      templateUrl: '/admin/templates/raletest.html',
      controller: window.RemoteAcademy.Controllers.RaleTestController,
      controllerAs: "rtc"
    });
    return $locationProvider.html5Mode({
      enabled: true
    });
  }
]).controller("AdminController", function() {
  this.base = window.location.origin;
  this.user = window.rauser;
  this.links = [
    {
      href: "/admin",
      title: "Dashboard"
    }, {
      href: "/admin/labs",
      title: "Labs"
    }, {
      href: "/admin/labsim",
      title: "LabBox Simulator"
    }
  ];
  return console.log(this.links);
});
