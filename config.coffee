# Remote.Academy Global Configuration
module.exports = {

  # Connects RemoteAcademy to its Mongo database
  MONGO_URL: (()->
    username = ""
    password = ""
    dbname = "remoteacademy-experimental"

    # Host URL
    "mongodb://#{username}:#{password}@ds049624.mongolab.com:49624/#{dbname}"
  )()

  # Connects RemoteAcademy to a CAS login system. Currently hard-wired to RPI
  CAS_AUTH_URL: process.env.CAS_AUTH_URL or "https://cas-auth.rpi.edu/cas"
  CAS_AUTH_DOMAIN: process.env.CAS_AUTH_DOMAIN or "rpi.edu"

  # Used for URL callbacks, such as in the authentication system
  DEFAULT_PORT: process.env.OPENSHIFT_NODE4_PORT or 3000
  APP_ADDRESS: if process.env.OPENSHIFT_NODE4_IP
      "http://remote.academy"
    else
      "http://remoteacademy.phys.rpi.edu:3000"

  # Authenticated Session Security Key
  SESSION_SECRET: process.env.SESSION_SECRET or "localhost secret"

  # When admin users create new documents, which groups should have access by default
  DEFAULT_ACCESS_GROUPS: ["dev"]
}
