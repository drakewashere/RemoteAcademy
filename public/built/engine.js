
/*
 _____               _         _____           _
| __  |___ _____ ___| |_ ___  |  _  |___ ___ _| |___ _____ _ _
|    -| -_|     | . |  _| -_|_|     |  _| .'| . | -_|     | | |
|__|__|___|_|_|_|___|_| |___|_|__|__|___|__,|___|___|_|_|_|_  |
========================================================= |___|
REMOTE.ACADEMY JAVASCRIPT FRONTEND
---------------------------------------------------------
 */
var ExperimentDataEvent;

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
    base = "/api/";
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
    this.get = function(endpoint, commonName) {
      if (commonName == null) {
        commonName = endpoint;
      }
      return $http.get("" + base + endpoint + "?nc=" + (Math.random()))["catch"](defaultErrorHandler.bind(this, commonName)).then(completionHandler.bind(this, commonName));
    };
    this.post = function(endpoint, data, commonName) {
      if (commonName == null) {
        commonName = endpoint;
      }
      return $http.post("" + base + endpoint, data)["catch"](defaultErrorHandler.bind(this, commonName)).then(completionHandler.bind(this, commonName));
    };
    this.updateUser = function(fields) {
      return this.post("user/update", fields, "UpdateUser");
    };
    this.registerForSection = function(cId, sId) {
      return this.get("user/register/" + cId + "/" + sId, "RegisterUser");
    };
    this.getSocketId = function() {
      return this.get("socketauth", "GetSocketID");
    };
    this.classSearch = function(query) {
      return this.get("class/" + (encodeURIComponent(query)), "ClassSearch");
    };
    this.listLabs = function() {
      return this.get("labs/list", "ListLabs");
    };
    this.getLab = function(id) {
      return this.get("labs/get/" + id, "GetLab");
    };
    this.submitNotebook = function(id) {
      return this.get("notebooks/submit/" + id, "SubmitNotebook");
    };
    this.getData = function(expId, dataId) {
      return this.get("data/" + expId + "/" + dataId, "GetExpData");
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
          return callback(true);
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

window.RemoteAcademy.Directives.raAutosave = function() {
  return {
    restrict: 'A',
    require: '^raAutosaveSection',
    scope: {
      raAutosave: "&"
    },
    link: function(scope, element, attrs, autosaveSection) {
      return element.on("input", function() {
        return scope.raAutosave({
          section: autosaveSection.section,
          value: this.value
        });
      });
    }
  };
};

window.RemoteAcademy.Directives.raAutosaveSection = function() {
  return {
    restrict: 'A',
    scope: {
      raAutosaveSection: "@"
    },
    controller: [
      "$scope", function($scope) {
        return this.section = parseInt($scope.raAutosaveSection);
      }
    ]
  };
};

window.RemoteAcademy.Directives.raDataTable = function() {
  return {
    restrict: 'E',
    replace: true,
    require: '^raAutosaveSection',
    scope: {
      raAutosave: "&"
    },
    scope: {
      columns: "@",
      data: "@",
      change: "&"
    },
    template: "<table class=\"datatable\" cellspacing=\"0\" cellpadding=\"0\">\n  <tr class=\"head\">\n    <th ng-repeat=\"column in real_columns\"\n        ng-bind=\"column.label\" ng-style=\"{width: column.width}\">\n    </th>\n    <th class=\"action\" ng-click=\"deleteAll()\">&#x2715;</th>\n  </tr>\n  <tr ng-repeat=\"row in real_data\" ng-show=\"real_data.length > 0\" class=\"datarow\">\n    <td ng-repeat=\"point in row track by $index\" ng-bind=\"point\"></td>\n    <td class=\"action\" ng-click=\"delete($index)\">&#x2715;</td>\n  </tr>\n  <tr ng-show=\"real_data.length == 0\">\n    <td colspan=\"{{real_columns.length}}\" class=\"tableEmpty\">No Data Yet</td>\n  </tr>\n</table>",
    link: function(scope, element, attrs, autosaveSection) {
      return scope.onChange = function() {
        return scope.change({
          section: autosaveSection.section,
          value: scope.real_data
        });
      };
    },
    controller: [
      "$scope", function($scope) {
        var error1;
        try {
          $scope.real_data = JSON.parse($scope.data);
        } catch (error1) {
          $scope.real_data = [];
        }
        $scope.real_columns = JSON.parse($scope.columns);
        document.addEventListener("experimentData", function(e) {
          var column, input, output, ref;
          ref = e.data, input = ref[0], output = ref[1];
          $scope.real_data.push((function() {
            var i, len, ref1, results;
            ref1 = $scope.real_columns;
            results = [];
            for (i = 0, len = ref1.length; i < len; i++) {
              column = ref1[i];
              if (column.input != null) {
                results.push(input[column.input]);
              } else if (column.output != null) {
                results.push(output[column.output]);
              } else {
                results.push(void 0);
              }
            }
            return results;
          })());
          return $scope.onChange();
        });
        $scope["delete"] = function(index) {
          $scope.real_data.splice(index, 1);
          return $scope.onChange();
        };
        return $scope.deleteAll = function(index) {
          if (!confirm("Are you sure you want to clear all data?")) {
            return;
          }
          $scope.real_data = [];
          return $scope.onChange();
        };
      }
    ]
  };
};

window.RemoteAcademy.Directives.raFooter = function() {
  return {
    restrict: 'E',
    replace: true,
    template: "<table class=\"footer\"><tr>\n  <td><a href=\"/register/class\"><b>Add Class</b></a></td>\n  <td><a href=\"/about\">About</a></td>\n  <td><a href=\"/legal\">Legal</a></td>\n  <td><a href=\"/logout\">Logout</a></td>\n</tr></table>"
  };
};

window.RemoteAcademy.Directives.raHeader = function() {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      banner: "@"
    },
    template: "<header>\n  <img src=\"/img/logo.svg\"></img>\n  <div class=\"banner\" ng-bind=\"banner\" ng-show=\"banner\"></div>\n</header>"
  };
};

window.RemoteAcademy.Directives.raNotebookFooter = function() {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      loading: "=",
      status: "="
    },
    template: "<table class=\"notebookfooter footer\"><tr>\n  <td style=\"width:auto\"></td>\n  <td><a href=\"/labs\">Back to Labs</a></td>\n  <td><a href=\"/help\">Help</a></td>\n  <td class=\"autosave\">\n    <img src=\"/img/loader.svg\" class=\"loader\" ng-show=\"loading\"/>\n    <p ng-hide=\"loading\" ng-bind=\"status\"></p>\n  </td>\n  <td style=\"width:auto\"></td>\n</tr></table>"
  };
};

window.RemoteAcademy.Directives.toggleButton = function() {
  return {
    restrict: 'A',
    scope: {
      'toggleButton': '&'
    },
    link: function(scope, element, attrs, autosaveSection) {
      var updateMode;
      updateMode = function(isOn) {
        scope.buttonOn = isOn;
        scope.toggleButton({
          state: isOn
        });
        element[0].innerHTML = isOn ? "On" : "Off";
        if (isOn) {
          return element.removeClass("off");
        } else {
          return element.addClass("off");
        }
      };
      updateMode(0);
      return element.on("click", function() {
        return updateMode(scope.buttonOn === 1 ? 0 : 1);
      });
    }
  };
};

window.RemoteAcademy.Directives.raAutosave = function() {
  return {
    restrict: 'A',
    require: '^raAutosaveSection',
    scope: {
      raAutosave: "&"
    },
    link: function(scope, element, attrs, autosaveSection) {
      return element.on("input", function() {
        return scope.raAutosave({
          section: autosaveSection.section,
          value: this.value
        });
      });
    }
  };
};

window.RemoteAcademy.Directives.raAutosaveSection = function() {
  return {
    restrict: 'A',
    scope: {
      raAutosaveSection: "@"
    },
    controller: [
      "$scope", function($scope) {
        return this.section = parseInt($scope.raAutosaveSection);
      }
    ]
  };
};

window.RemoteAcademy.Directives.raDataTable = function() {
  return {
    restrict: 'E',
    replace: true,
    require: '^raAutosaveSection',
    scope: {
      raAutosave: "&"
    },
    scope: {
      columns: "@",
      data: "@",
      change: "&"
    },
    template: "<table class=\"datatable\" cellspacing=\"0\" cellpadding=\"0\">\n  <tr class=\"head\">\n    <th ng-repeat=\"column in real_columns\"\n        ng-bind=\"column.label\" ng-style=\"{width: column.width}\">\n    </th>\n    <th class=\"action\" ng-click=\"deleteAll()\">&#x2715;</th>\n  </tr>\n  <tr ng-repeat=\"row in real_data\" ng-show=\"real_data.length > 0\" class=\"datarow\">\n    <td ng-repeat=\"point in row track by $index\" ng-bind=\"point\"></td>\n    <td class=\"action\" ng-click=\"delete($index)\">&#x2715;</td>\n  </tr>\n  <tr ng-show=\"real_data.length == 0\">\n    <td colspan=\"{{real_columns.length}}\" class=\"tableEmpty\">No Data Yet</td>\n  </tr>\n</table>",
    link: function(scope, element, attrs, autosaveSection) {
      return scope.onChange = function() {
        return scope.change({
          section: autosaveSection.section,
          value: scope.real_data
        });
      };
    },
    controller: [
      "$scope", function($scope) {
        var error1;
        try {
          $scope.real_data = JSON.parse($scope.data);
        } catch (error1) {
          $scope.real_data = [];
        }
        $scope.real_columns = JSON.parse($scope.columns);
        document.addEventListener("experimentData", function(e) {
          var column, input, output, ref;
          ref = e.data, input = ref[0], output = ref[1];
          $scope.real_data.push((function() {
            var i, len, ref1, results;
            ref1 = $scope.real_columns;
            results = [];
            for (i = 0, len = ref1.length; i < len; i++) {
              column = ref1[i];
              if (column.input != null) {
                results.push(input[column.input]);
              } else if (column.output != null) {
                results.push(output[column.output]);
              } else {
                results.push(void 0);
              }
            }
            return results;
          })());
          return $scope.onChange();
        });
        $scope["delete"] = function(index) {
          $scope.real_data.splice(index, 1);
          return $scope.onChange();
        };
        return $scope.deleteAll = function(index) {
          if (!confirm("Are you sure you want to clear all data?")) {
            return;
          }
          $scope.real_data = [];
          return $scope.onChange();
        };
      }
    ]
  };
};

window.RemoteAcademy.Directives.raHeader = function() {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      banner: "@"
    },
    template: "<header>\n  <img src=\"/img/logo.svg\"></img>\n  <div class=\"banner\" ng-bind=\"banner\" ng-show=\"banner\"></div>\n</header>"
  };
};

window.RemoteAcademy.Directives.raFooter = function() {
  return {
    restrict: 'E',
    replace: true,
    template: "<table class=\"footer\"><tr>\n  <td><a href=\"/register/class\"><b>Add Class</b></a></td>\n  <td><a href=\"/about\">About</a></td>\n  <td><a href=\"/legal\">Legal</a></td>\n  <td><a href=\"/logout\">Logout</a></td>\n</tr></table>"
  };
};

window.RemoteAcademy.Directives.raNotebookFooter = function() {
  return {
    restrict: 'E',
    replace: true,
    scope: {
      loading: "=",
      status: "="
    },
    template: "<table class=\"notebookfooter footer\"><tr>\n  <td style=\"width:auto\"></td>\n  <td><a href=\"/labs\">Back to Labs</a></td>\n  <td><a href=\"/help\">Help</a></td>\n  <td class=\"autosave\">\n    <img src=\"/img/loader.svg\" class=\"loader\" ng-show=\"loading\"/>\n    <p ng-hide=\"loading\" ng-bind=\"status\"></p>\n  </td>\n  <td style=\"width:auto\"></td>\n</tr></table>"
  };
};

window.RemoteAcademy.Directives.toggleButton = function() {
  return {
    restrict: 'A',
    scope: {
      'toggleButton': '&'
    },
    link: function(scope, element, attrs, autosaveSection) {
      var updateMode;
      updateMode = function(isOn) {
        scope.buttonOn = isOn;
        scope.toggleButton({
          state: isOn
        });
        element[0].innerHTML = isOn ? "On" : "Off";
        if (isOn) {
          return element.removeClass("off");
        } else {
          return element.addClass("off");
        }
      };
      updateMode(0);
      return element.on("click", function() {
        return updateMode(scope.buttonOn === 1 ? 0 : 1);
      });
    }
  };
};


/*
The MIT License (MIT)

Copyright (c) 2015 Joseph Wynn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

angular.module('relativeDate', []).value('now', null).value('relativeDateTranslations', {
  just_now: 'just now',
  seconds_ago: '{{time}} seconds ago',
  a_minute_ago: 'a minute ago',
  minutes_ago: '{{time}} minutes ago',
  an_hour_ago: 'an hour ago',
  hours_ago: '{{time}} hours ago',
  a_day_ago: 'yesterday',
  days_ago: '{{time}} days ago',
  a_week_ago: 'a week ago',
  weeks_ago: '{{time}} weeks ago',
  a_month_ago: 'a month ago',
  months_ago: '{{time}} months ago',
  a_year_ago: 'a year ago',
  years_ago: '{{time}} years ago',
  over_a_year_ago: 'over a year ago',
  seconds_from_now: 'in {{time}} seconds',
  a_minute_from_now: 'in 1 minute',
  minutes_from_now: 'in {{time}} minutes',
  an_hour_from_now: 'in an hour',
  hours_from_now: 'in {{time}} hours',
  a_day_from_now: 'tomorrow',
  days_from_now: 'in {{time}} days',
  a_week_from_now: 'in a week',
  weeks_from_now: 'in {{time}} weeks',
  a_month_from_now: 'in a month',
  months_from_now: 'in {{time}} months',
  a_year_from_now: 'in a year',
  years_from_now: 'in {{time}} years',
  over_a_year_from_now: 'in over a year'
}).filter('relativeDate', [
  '$injector', 'now', 'relativeDateTranslations', function($injector, _now, relativeDateTranslations) {
    var $translate, calculateDelta;
    if ($injector.has('$translate')) {
      $translate = $injector.get('$translate');
    } else {
      $translate = {
        instant: function(id, params) {
          return relativeDateTranslations[id].replace('{{time}}', params.time);
        }
      };
    }
    calculateDelta = function(now, date) {
      return Math.round(Math.abs(now - date) / 1000);
    };
    return function(date) {
      var day, delta, hour, minute, month, now, translate, week, year;
      now = _now ? _now : new Date();
      if (!(date instanceof Date)) {
        date = new Date(date);
      }
      delta = null;
      minute = 60;
      hour = minute * 60;
      day = hour * 24;
      week = day * 7;
      month = day * 30;
      year = day * 365;
      delta = calculateDelta(now, date);
      if (delta > day && delta < week) {
        date = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
        delta = calculateDelta(now, date);
      }
      translate = function(translatePhrase, timeValue) {
        var translateKey;
        if (translatePhrase === 'just_now') {
          translateKey = translatePhrase;
        } else if (now >= date) {
          translateKey = translatePhrase + "_ago";
        } else {
          translateKey = translatePhrase + "_from_now";
        }
        return $translate.instant(translateKey, {
          time: timeValue
        });
      };
      switch (false) {
        case !(delta < 30):
          return translate('just_now');
        case !(delta < minute):
          return translate('seconds', delta);
        case !(delta < 2 * minute):
          return translate('a_minute');
        case !(delta < hour):
          return translate('minutes', Math.floor(delta / minute));
        case Math.floor(delta / hour) !== 1:
          return translate('an_hour');
        case !(delta < day):
          return translate('hours', Math.floor(delta / hour));
        case !(delta < day * 2):
          return translate('a_day');
        case !(delta < week):
          return translate('days', Math.floor(delta / day));
        case Math.floor(delta / week) !== 1:
          return translate('a_week');
        case !(delta < month):
          return translate('weeks', Math.floor(delta / week));
        case Math.floor(delta / month) !== 1:
          return translate('a_month');
        case !(delta < year):
          return translate('months', Math.floor(delta / month));
        case Math.floor(delta / year) !== 1:
          return translate('a_year');
        default:
          return translate('over_a_year');
      }
    };
  }
]);

window.RemoteAcademy.Controllers.LabViewController = (function() {
  function LabViewController($routeParams, $rootScope, $scope, $location, raAPI, socket) {
    this.$scope = $scope;
    this.$location = $location;
    this.api = raAPI;
    this.lab = $routeParams.id;
    this.socket = socket;
    this.clientID = $scope.app.user.id;
    this.autosaveLoading = true;
    this.autosaveStatus = "Loading";
    this.experiment = {};
    this.activeExperiment = false;
    this.update = {};
    this.debounce = 1000;
    this.hasSaved = false;
    this.onRouteChangeOff = $rootScope.$on('$locationChangeStart', this.routeChange.bind(this));
    this.socket.connect((function(_this) {
      return function(success, error) {
        if (!success) {
          return alert("Received WS Error. Try refreshing the page. '" + error + "'");
        }
        _this.autosaveLoading = false;
        return _this.autosaveStatus = "Autosave Ready";
      };
    })(this));
  }

  LabViewController.prototype.startExperiment = function(experimentID) {
    if (this.experiment[experimentID] != null) {
      this.socket.emit("finish", true, (function(_this) {
        return function(success) {
          _this.activeExperiment = false;
          return delete _this.experiment[experimentID];
        };
      })(this));
      return;
    }
    this.experiment[experimentID] = {
      status: "Connecting to Experiment",
      failed: false,
      waiting: true,
      connected: false
    };
    this.socket.emit("start", experimentID, (function(_this) {
      return function(failure) {
        if ((failure != null ? failure.code : void 0) === 1023) {
          return _this.experiment[experimentID] = {
            status: "There are no LabBoxes online",
            failed: true,
            waiting: false
          };
        }
      };
    })(this));
    this.socket.on("queueProgress", (function(_this) {
      return function(arg) {
        var experiment, position;
        experiment = arg.experiment, position = arg.position;
        return _this.experiment[experimentID] = {
          status: position === 1 ? "Next in Queue" : "Number " + position + " in Queue",
          failed: false,
          waiting: true
        };
      };
    })(this));
    return this.socket.once("connected", (function(_this) {
      return function(data) {
        new Audio('/img/Boop.mp3').play();
        _this.timeout = data.timeout;
        _this.experimentID = experimentID;
        _this.experiment[experimentID] = {
          status: "Finish Experiment",
          failed: false,
          waiting: false,
          connected: true,
          templateUrl: "/templates/experiment/" + experimentID,
          setup: data.experiment.setup
        };
        return _this.setupExperiment(experimentID);
      };
    })(this));
  };

  LabViewController.prototype.setupExperiment = function(experimentID) {
    this.activeExperiment = experimentID;
    this.socket.on("image", function(jpegData) {
      var element, frame;
      frame = "data:image/jpeg;base64," + jpegData;
      element = document.getElementById("frame-" + experimentID);
      return element.setAttribute("src", frame);
    });
    this.lastSample = 0;
    return this.socket.on("data", (function(_this) {
      return function(data) {
        return alert("CURRENTLY UNSUPPORTED");
      };
    })(this));
  };

  LabViewController.prototype.manualSample = function() {
    return this.lastSample = new Date().getTime + 100000;
  };

  LabViewController.prototype.endExperiment = function() {
    return this.socket.emit("disconnect", {});
  };

  LabViewController.prototype.toggleStreaming = function() {
    if (this.collecting) {
      this.socket.emit("stopCollecting", {});
    } else {
      this.socket.emit("startStreaming", {});
    }
    return this.collecting = !this.collecting;
  };

  LabViewController.prototype.triggerCollection = function(experimentID, time) {
    this.socket.emit("startCollecting", time);
    this.collecting = true;
    return this.socket.once("collected", (function(_this) {
      return function(ret) {
        _this.collecting = false;
        return _this.api.getData(experimentID, ret.cacheID).then(function(data) {
          var link;
          link = document.createElement("a");
          link.setAttribute("href", 'data:text/csv;base64,' + btoa(data));
          link.setAttribute("download", "collected_data.csv");
          return link.click();
        });
      };
    })(this));
  };

  LabViewController.prototype.updateInput = function(device, id, value) {
    var i, input, inputs, len, ref, ref1, ref2, send, ti;
    value = parseInt(value);
    console.log(this.experiment, this.activeExperiment, device, id);
    inputs = (ref = this.experiment[this.activeExperiment]) != null ? (ref1 = ref.setup) != null ? (ref2 = ref1[device]) != null ? ref2.inputs : void 0 : void 0 : void 0;
    if (!inputs) {
      return;
    }
    for (i = 0, len = inputs.length; i < len; i++) {
      ti = inputs[i];
      if (ti.id === id) {
        input = ti;
      }
    }
    if (!input) {
      return alert("[ERROR] Misconfigured input: " + id);
    }
    input.value = value;
    if (input.map != null) {
      value = new Function('x', "return " + input.map)(value);
    }
    send = {
      device: device,
      key: id,
      value: value
    };
    return this.socket.emit("control", send);
  };

  LabViewController.prototype.saveSection = function(section, name, value) {
    if (this.hasSaved) {
      this.autosaveStatus = "Recently Saved";
    }
    this.update["values." + section + "." + name] = value;
    if (this.lastTimeout != null) {
      clearTimeout(this.lastTimeout);
    }
    return this.lastTimeout = wait(this.debounce, (function(_this) {
      return function() {
        _this.$scope.$apply(function() {
          return _this.autosaveStatus = "Saving Changes...";
        });
        return _this.socket.emit("save", {
          lab: _this.lab,
          update: _this.update
        }, function(result) {
          if (result) {
            _this.autosaveStatus = "All Changes Saved";
            _this.update = {};
            return _this.hasSaved = true;
          } else {
            return _this.autosaveStatus = "Save Failed!";
          }
        });
      };
    })(this));
  };

  LabViewController.prototype.routeChange = function() {
    if (JSON.stringify(this.update) !== "{}") {
      this.socket.emit("save", {
        lab: this.lab,
        update: this.update
      });
    }
    return this.onRouteChangeOff();
  };

  LabViewController.prototype.submitNotebook = function() {
    this.routeChange();
    return this.api.submitNotebook(this.lab).then((function(_this) {
      return function() {
        return _this.$location.path("/success");
      };
    })(this));
  };

  return LabViewController;

})();

window.RemoteAcademy.Controllers.LabViewController.$inject = ["$routeParams", "$rootScope", "$scope", "$location", "raAPI", "socket"];

ExperimentDataEvent = (function() {
  function ExperimentDataEvent(data) {
    var evt;
    evt = new CustomEvent("experimentData");
    evt.data = data;
    return evt;
  }

  return ExperimentDataEvent;

})();

window.RemoteAcademy.Controllers.LabListController = (function() {
  function LabListController($location, $http, raAPI) {
    this.$location = $location;
    this.loading = true;
    raAPI.listLabs().then((function(_this) {
      return function(classes) {
        _this.classes = classes;
        return _this.loading = false;
      };
    })(this));
  }

  LabListController.prototype.open = function(labID) {
    return this.$location.path("/lab/" + labID);
  };

  return LabListController;

})();

window.RemoteAcademy.Filters.dueColor = function() {
  return function(date) {
    var cDate, hrDiff, secDiff;
    cDate = new Date().getTime();
    secDiff = Math.round((date - cDate) / 1000);
    hrDiff = secDiff / 3600;
    if (hrDiff < 4) {
      return "#FF4949";
    }
    if (hrDiff < 24) {
      return "#FFC659";
    }
    return "#A0D768";
  };
};

window.RemoteAcademy.Controllers.LabListController.$inject = ["$location", "$http", "raAPI"];

window.RemoteAcademy.Controllers.RegisterAccountController = (function() {
  function RegisterAccountController($scope, $location, raAPI) {
    this.$location = $location;
    this.$scope = $scope;
    this.api = raAPI;
    this.email = $scope.app.user.username + "@" + $scope.app.user.domain;
    this.labNotify = true;
    this.name = "";
  }

  RegisterAccountController.prototype.submit = function() {
    return this.api.updateUser({
      email: this.email,
      notifications: {
        lab: this.labNotify
      },
      fullname: this.name ? this.name : "Anonymous"
    }).then((function(_this) {
      return function() {
        _this.$scope.app.user.email = _this.email;
        _this.$scope.app.user.fullname = _this.name !== "" ? _this.name : void 0;
        _this.$scope.app.user.notifications = {
          lab: _this.labNotify
        };
        return _this.$location.path('/register/class');
      };
    })(this));
  };

  return RegisterAccountController;

})();

window.RemoteAcademy.Controllers.RegisterAccountController.$inject = ["$scope", "$location", "raAPI"];

window.RemoteAcademy.Controllers.ClassSearchController = (function() {
  function ClassSearchController($scope, $location, raAPI) {
    this.$location = $location;
    this.api = raAPI;
    this.loading = false;
    this.empty = false;
    this.classes = [];
    this.selected = -1;
    $scope.$watch("rac.query", (function(_this) {
      return function(newval) {
        if ((newval == null) || newval === "") {
          return;
        }
        _this.loading = true;
        _this.classes = [];
        return _this.api.classSearch(newval).then(function(classes) {
          _this.loading = false;
          _this.empty = classes.length === 0;
          return _this.classes = classes;
        });
      };
    })(this));
  }

  ClassSearchController.prototype.select = function(classObject, section) {
    if (!confirm("Are you sure you want to sign up for:\n  \"" + classObject.name + "\" with " + classObject.professor + "\n  " + section.name + " (" + section.timeslot + ")")) {
      return;
    }
    return this.api.registerForSection(classObject["_id"], section.id).then((function(_this) {
      return function(success) {
        if (success) {
          return _this.$location.path("/labs");
        } else {
          return alert("An unknown error occurred, please contact your professor or TA");
        }
      };
    })(this));
  };

  return ClassSearchController;

})();

window.RemoteAcademy.Controllers.ClassSearchController.$inject = ["$scope", "$location", "raAPI"];

angular.module('RAFrontend', ["ngRoute", "ngSanitize", "relativeDate", "RAFrontendTemplates"]).controller(window.RA.Controllers).directive(window.RA.Directives).service(window.RA.Services).factory(window.RA.Factories).filter(window.RA.Filters).config([
  "$routeProvider", "$locationProvider", function($routeProvider, $locationProvider) {
    $routeProvider.when("/logout", {
      templateUrl: function() {
        return location.reload();
      }
    }).when("/register/account", {
      templateUrl: '/templates/register/account.html',
      controller: window.RemoteAcademy.Controllers.RegisterAccountController,
      controllerAs: "rac"
    }).when("/register/class", {
      templateUrl: '/templates/register/class.html',
      controller: window.RemoteAcademy.Controllers.ClassSearchController,
      controllerAs: "csc"
    }).when("/labs", {
      templateUrl: '/templates/lablist.html',
      controller: window.RemoteAcademy.Controllers.LabListController,
      controllerAs: "llc"
    }).when("/lab/:id", {
      templateUrl: function(urlattr) {
        return "/templates/lab/" + urlattr.id + "?nc=" + (Math.random());
      },
      controller: window.RemoteAcademy.Controllers.LabViewController,
      controllerAs: "lc"
    }).when("/success", {
      templateUrl: '/templates/success.html'
    });
    return $locationProvider.html5Mode({
      enabled: true,
      requireBase: false
    });
  }
]).controller("AppController", function() {
  this.base = window.location.origin;
  return this.user = window.rauser;
});
