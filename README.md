# Remote.Academy
### Rensselaer Polytechnic Institute
### Sponsored by RPI Physics Department and Rensselaer Center for Open Source Software
### Hosted at http://remoteacademy.phys.rpi.edu/ 
### in collaboration with RPI DOTCIO and Office of Undergraduate Education
Originally created by: *Miles Konstantin, Osvaldo Rosado and Keaton Brandt*
Currently maintained by: *Karl Nasrallah, Cole Baxter, Zoran Lalvani, Harrison Lee, Richi Young*
***

## Running RemoteAcademy

1. Install these tools on your computer (Windows, Mac, or Linux)

* NPM 3 or higher
* Node 4 or higher

2. Download or `git checkout` this repository

3. In a command line, navigate to the directory you downloaded and install the dependencies
  `sudo npm install`

4. In a command line, start the server
  `node app`

You should now be able to access the RemoteAcademy front-end interface running on your
local computer. The Node command line will inform you of the port.


## Making changes

1. In a command line, install Gulp globally
  `sudo npm install -g gulp`

2. In a command line, navigate to the RemoteAcademy directory and start the build system
  `gulp watch`

3. Make changes.

* Changes to ./server will require the server to be restarted
* Changes to ./public or ./admin will usually just work


## Deploying to OpenShift

We are currently using RedHat's OpenShift to host http://remote.academy

Deployment should be as easy as logging in to the server and running
`rhc app-force-stop -a ra`, although we've found it to be rather buggy.

***

## Tech Stack

### Server Technologies

* **REST API:** A special kind of application programming interface based on a stateless
structure. This means that every request from the client contains all of the data necessary
for the server to process it. The server does not store sessions or anything of that nature.
Basically, think of the server as the DMV - If you want it to do what you want, you better
have all of the information it needs, and don't expect it to remember you from last time.

* **WebSocket:** Most HTTP connections are "One and Done" - meaning that the client requests
some data, the server sends it back, and then the transaction is done. This adds a lot of
overhead to situations where the client and server want to be in frequent communication with
each-other. One solution is WebSockets, which stay open and allow both the client and
server to 'push' data to the other.

* **CAS / OAuth:** OAuth is a secure way for a user to log in to a website using a third
party service. This is how "Login with Facebook" buttons work. Schools aren't Facebook, but
it turns out many of them (including RPI) do have OAuth-compatible login systems. The
specific standard they usually use is called CAS (Common Authentication System).


### Server Tools

* **Coffeescript:** A python-like programming language that lightly compiles to Javascript.
All of the APIs are pure JS, the only difference is syntax. Coffeescript supports many ES6
features, allowing modern code to be written now, even before browser support catches up.

* **Node JS:** Hopefully you've heard of this one by now. It's server software built on top
of Google's V8 Javascript interpreter. What this means: The frontend and backend code can be
written in the same language and even share code.

* **MongoDB:** A modern type of database structured with 'documents' instead of 'rows'. This
allows for much more versatile data storage without sacrificing performance.

* **Koa JS:** The successor to Express.js. This handles HTTP serving (which, surprisingly,
is not really built into Node itself). It is built around a Javascript library called Co
that uses generator functions to retrieve asynchronous values without using callback
functions or promises. What this means: cleaner code, less functional overhead. Win/win!

* **RedHat OpenShift:** A cloud hosting platform with a generous free tier.


### Frontend Tools

* **Angular.js 1.x:** Google's answer to web app development, this Javascript framework
enables us to write structured, reusable code. Angular has directives, which represent HTML
components, and services, which represent singleton libraries and controllers.

* **SASS:** A modern take on CSS that has variables and nesting, along with other features.
It also eschews brackets, allowing it to better match our Coffeescript.

* **Gulp:** Gulp is a simple build system for frontend code that is configured using (you
guessed it) Javascript! Everything is Javascript now! Whee! We use it to compile SASS
and Coffeescript, as well as inlining Angular templates to speed up load times.
