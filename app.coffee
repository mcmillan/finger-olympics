# Require express + deps
express = require('express')
http = require('http')
path = require('path')

# Require passport + FB strategy
passport = require('passport')
passportFacebookStrategy = require('passport-facebook').Strategy

# Require NowJS
nowjs = require('now')

# Get configuration from config.coffee (not in repo for obvious reasons, app secret theft sucks)
config = require('./config.coffee')

# Configure passport
passport.use(

  new passportFacebookStrategy

    clientID: config.facebook.app_id
    clientSecret: config.facebook.app_secret
    callbackURL: '/auth', # hard coding ftw

    (access_token, refresh_token, profile, done) ->

      done null, profile

)

passport.serializeUser (user, done) ->

  done null, user

passport.deserializeUser (user, done) ->

  done null, user

# Initialise + configure Express
app = express()

app.configure ->

  app.set 'port', process.env.PORT or 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser('pugs are the best')
  app.use express.session()
  app.use passport.initialize()
  app.use passport.session()
  app.use require('connect-assets')()
  app.use app.router
  app.use express.static(path.join(__dirname, 'public'))
  app.use express.errorHandler()

# Define Express routes
app.all '/', (req, res) ->

  qr_url = 'https://chart.googleapis.com/chart?cht=qr&chs=300x300&chl=' + encodeURIComponent('http://' + req.headers.host + '/play')

  res.render 'web/available', qr: qr_url

app.get '/play', (req, res) ->

  res.render (if req.isAuthenticated() then 'play/auth' else 'play/no_auth'), user: JSON.stringify(req.user or null)

app.get '/auth', passport.authenticate 'facebook', successRedirect: '/play', failureRedirect: '/play', scope: ['publish_actions'], display: 'touch'

# Boot up server
server = http.createServer(app).listen app.get('port')

# Initialise NowJS
everyone = nowjs.initialize server

everyone.now.backfill_players = ->

  everyone.getUsers (players) ->

    players.forEach (id) ->

      nowjs.getClient id, ->

        if !@now.user
          return

        everyone.now.receive_new_player @now.user

everyone.now.new_player = ->

  everyone.now.receive_new_player @now.user

nowjs.on 'disconnect', ->

  everyone.now.receive_lost_player @now.user