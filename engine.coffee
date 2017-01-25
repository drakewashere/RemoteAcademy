###
 _____               _         _____           _
| __  |___ _____ ___| |_ ___  |  _  |___ ___ _| |___ _____ _ _
|    -| -_|     | . |  _| -_|_|     |  _| .'| . | -_|     | | |
|__|__|___|_|_|_|___|_| |___|_|__|__|___|__,|___|___|_|_|_|_  |
========================================================= |___|
REMOTE.ACADEMY "MIDDLE-MAN" SERVER
RUN WITH "node app" or "npm start"
---------------------------------------------------------
###

Koa = require 'koa'
app = new Koa()

serve = require 'koa-static'
serve_folder = require 'koa-static-folder'
router = require 'koa-route'
send = require 'koa-send'
handlebars = require 'koa-handlebars'
bodyParser = require 'koa-bodyparser'

config = require './config'
session = require 'koa-generic-session'
passport = require 'koa-passport'
authentication = require './server/authentication'


# HELPERS ==================================================================================
GLOBAL.wait = (d, f)-> setTimeout f, d
GLOBAL.every = (d, f)-> setInterval f, d


# LOGGER ===================================================================================
app.use (next)->
  start = new Date
  yield next
  ms = new Date - start
  console.log "#{@method} #{@url} - #{ms}ms"


# CAS AUTHENTICATION =======================================================================
app.keys = [config.SESSION_SECRET]
app.use(session())

app.use passport.initialize()
app.use passport.session()

authentication.configure config.CAS_AUTH_URL, config.CAS_AUTH_DOMAIN, config.APP_ADDRESS

app.use router.get "/login", passport.authenticate("cas")
app.use router.get "/login", require './server/REST/login.coffee'
app.use router.get "/logout", require './server/REST/logout.coffee'

# Kick the user off the homepage if they're logged in
app.use router.get "/", (next)->
  if @req.isAuthenticated() then @redirect "/labs"
  else yield next


# STATIC ====================================================================================
app.use serve "./public"
app.use serve_folder "./admin"

app.use router.get '/labbox/environment/init.py', ()->
  yield return @redirect "http://labbox-update.remote.academy/init.py"


# REST API =================================================================================
app.use bodyParser()

app.use router.get '/api/about', require './server/REST/about.coffee'
app.use router.get '/api/labs/list', require './server/REST/listlabs.coffee'
app.use router.get '/api/labs/get/:id', require './server/REST/getlab.coffee'
app.use router.get '/api/socketauth', require './server/REST/getsocketid.coffee'
app.use router.get '/api/class/:query', require './server/REST/classsearch.coffee'
app.use router.get '/api/user/register/:classId/:sectionId',
  require './server/REST/register.coffee'
app.use router.get '/api/notebooks/submit/:id', require './server/REST/submitnotebook.coffee'
app.use router.get '/api/data/:exp/:cache', require './server/REST/getstoreddata.coffee'

app.use router.post '/api/user/update', require './server/REST/updateuser.coffee'


# ADMIN API ================================================================================

ADMINAPI = (url, func, method="get") -> router[method] '/admin/api/' + url, ()->
  if !@req.user? or !@req.user['admin']
    @res.status = 404
    yield return
  else
    yield func.apply(this, arguments)

app.use ADMINAPI 'experiments/list', require './server/admin/listexperiments.coffee'
app.use ADMINAPI 'classes/list', require './server/admin/listclasses.coffee'
app.use ADMINAPI 'labs/list', require './server/admin/listlabs.coffee'
app.use ADMINAPI 'objectid', require './server/admin/makeobjectid.coffee'

app.use ADMINAPI 'experiments/forlabbox/:id',
  require './server/admin/getexperimentforlabbox.coffee'
app.use ADMINAPI 'access/grant/:id/:type/:name',
  require './server/admin/access_grant.coffee'
app.use ADMINAPI 'access/remove/:id/:type/:name',
  require './server/admin/access_remove.coffee'

app.use ADMINAPI 'crud/replace/:c', require('./server/admin/replacedocument.coffee'), 'post'
app.use ADMINAPI 'crud/insert/:c', require('./server/admin/adddocument.coffee'), 'post'
app.use ADMINAPI 'crud/query/:c', require('./server/admin/query.coffee'), 'post'
app.use ADMINAPI 'crud/ids/:c', require('./server/admin/getdocumentsbyids.coffee'), 'post'
app.use ADMINAPI 'crud/delete/:c/:id', require './server/admin/deletedocument.coffee'
app.use ADMINAPI 'crud/get/:c/:id', require './server/admin/getdocumentbyid.coffee'

app.use ADMINAPI 'images/upload/:l', require('./server/admin/uploadimage.coffee'), 'post'

# HTML TEMPLATES ===========================================================================
app.use router.get '/templates/lab/:id', require './server/HTML/lab.coffee'
app.use router.get '/templates/experiment/:id', require './server/HTML/experiment.coffee'


# WEBSOCKET API ============================================================================
server = require('http').Server app.callback()
io = require('socket.io')(server)
io.of('/client').on 'connection', require('./server/WS/client.coffee')
io.of('/rale').on 'connection', require('./server/WS/rale.coffee')


# ROUTE TO ANGULAR =========================================================================

# Handlebars is used to insert some JS data into the page
app.use(handlebars({
  viewsDir: './public/'
}));

app.use router.get '/admin/:path*', ()->
  if !@req.isAuthenticated() then return @redirect "/"
  if !@req.user['admin'] then return @redirect "/"
  yield @render '../admin/app.html', {user: JSON.stringify(@req.user)}

app.use router.get '/register/:page', ()->
  # If the user isn't logged in, force them to the homepage
  if !@req.isAuthenticated() or !@req.user?.username then return @redirect "/"

  {username, fullname, domain, _id: id} = @req.user
  yield @render 'app.html', {user: JSON.stringify({username, fullname, domain, id})}

app.use router.get '*', ()->

  # If the user isn't logged in, force them to the homepage
  if !@req.isAuthenticated() or !@req.user?.username then return @redirect "/"

  # If the user hasn't finished registering, take them to the onboarding page
  if !@req.user.email? then return @redirect "/register/account"

  # If the user hasn't added any classes, take them to registration
  if @req.user.classes.length is 0 then return @redirect "/register/class"

  {username, fullname, domain, _id: id} = @req.user
  yield @render 'app.html', {user: JSON.stringify({username, fullname, domain, id})}


# ERROR HANDLING ===========================================================================
app.use (next)->
  this.body = {error: 1, message: "An unknown error has occured", data: {}}
  yield return


# START ====================================================================================
port = process.env.OPENSHIFT_NODE4_PORT || 3000
ip = process.env.OPENSHIFT_NODE4_IP || "0.0.0.0"
console.log "REMOTE.ACADEMY: Listening on #{config.APP_ADDRESS}"
server.listen port, ip
