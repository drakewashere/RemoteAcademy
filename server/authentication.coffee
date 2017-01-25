co = require "co"
passport = require "koa-passport"
CASStrategy = require("passport-cas").Strategy
database = require "./database"
ObjectID = require('mongodb').ObjectID;

module.exports =
	configure: (authUrl, authDomain, baseUrl) ->

		casConfig =
			version: 'CAS3.0',
			ssoBaseURL: authUrl,
			serverBaseURL: baseUrl

		# Create a new Passport object using CAS
		passport.use new CASStrategy casConfig, (profile, done)=>

		  # Get the username
			username = profile.user.toLowerCase();
			co ()->
				db = yield database.connect()
				list = yield db.queryCollection("users", {username: username, domain: authDomain}, 2)

				# Create a new user
				if list.length is 0
					user = {
						username: username,
						domain: authDomain,
						classes: []
					}
					row = yield db.insert "users", user
					done null, row.ops[0]

				else if list.length > 1 then done "Database Error: Duplicated User"
				done null, list[0]


		passport.serializeUser (user, done)-> done null, user["_id"]

		passport.deserializeUser (id, done)=>
			co ()->
				db = yield database.connect()

				# Get the user, excluding the notebooks field which can be very large
				list = yield db.queryCollection("users", {"_id": ObjectID(id)}, 2)

				if list.length is 0 then done null, null
				else if list.length > 1 then done "Database Error: Duplicated User"
				done null, list[0]
