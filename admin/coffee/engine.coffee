###
 _____               _         _____           _
| __  |___ _____ ___| |_ ___  |  _  |___ ___ _| |___ _____ _ _
|    -| -_|     | . |  _| -_|_|     |  _| .'| . | -_|     | | |
|__|__|___|_|_|_|___|_| |___|_|__|__|___|__,|___|___|_|_|_|_  |
========================================================= |___|
REMOTE.ACADEMY JAVASCRIPT ADMIN INTERFACE
---------------------------------------------------------
###

window.RemoteAcademy = window.RA = {
  Controllers: {}
  Directives: {}
  Services: {}
  Factories: {}

  Filters: {
    "firstname": ()-> (str)-> str.split(" ")[0]
  }
}

window.wait = (d, f)-> setTimeout f, d
window.every = (d, f)-> setInterval f, d
