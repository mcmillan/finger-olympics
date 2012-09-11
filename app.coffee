# Require express + deps
express = require('express')
http = require('http')
path = require('path')

# Require passport + FB strategy
passport = require('passport')
passportFacebookStrategy = require('passport-facebook').Strategy

# Require NowJS
nowjs = require('now')

# Require Shred
shred = require('shred')
shred = new shred(logCurl: true)

# Get configuration from config.coffee (not in repo for obvious reasons, app secret theft sucks)
config = require('./config.coffee')

# Configure passport
passport.use(

  new passportFacebookStrategy

    clientID: config.facebook.app_id
    clientSecret: config.facebook.app_secret
    callbackURL: '/auth', # hard coding ftw

    (access_token, refresh_token, profile, done) ->

      profile.access_token = access_token

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
app.get '/', (req, res) ->

  res.redirect 'http://apps.facebook.com/fingerolympics/'

app.post '/', (req, res) ->

  qr_url = 'https://chart.googleapis.com/chart?cht=qr&chs=300x300&chl=' + encodeURIComponent('http://' + req.headers.host + '/play')

  res.render 'web/available', qr: qr_url

app.get '/play', (req, res) ->

  everyone.count (count)->

    console.log count

    if count < 15
      res.render (if req.isAuthenticated() then 'play/auth' else 'play/no_auth'), user: JSON.stringify(req.user or null)
    else
      res.send 'Too many players, sorry!'

app.get '/auth', passport.authenticate 'facebook', successRedirect: '/play', failureRedirect: '/play', scope: ['publish_actions'], display: 'touch'

# Boot up server
server = http.createServer(app).listen app.get('port')

# Initialise NowJS
everyone = nowjs.initialize server

race_occurring = false

everyone.now.backfill_players = ->

  everyone.getUsers (players) ->

    players.forEach (id) ->

      nowjs.getClient id, ->

        if !@now.user
          return

        everyone.now.receive_new_player @now.user

everyone.now.new_player = ->

  everyone.now.receive_new_player @now.user

everyone.now.start_game = ->

  everyone.getUsers (players) ->

    players.forEach (id) ->

      nowjs.getClient id, ->

        if !@now.user
          return

        everyone.now.add_lane @now.user
  
    everyone.now.show_game()
    race_occurring = true

everyone.now.on_tap = ->

  if !@now.user or !race_occurring
    return

  if !@now.position?
    @now.position = 1
  else
    @now.position += 1

  if @now.position >= 100
    everyone.now.post_og @now.user
    everyone.now.finished @now.user
    race_occurring = false
    return

  everyone.now.move @now.user.id, @now.position

everyone.now.post_og = (winner) ->

  if !@now.user or !@now.user.access_token
    return

  action = if winner.id is @now.user.id then 'win' else 'lose'

  shred.post

    url: 'https://graph.facebook.com/me/fingerolympics:' + action
    body: 'access_token=' + @now.user.access_token + '&event=http://sallyokelly.co.uk/josh/object.html'

nowjs.on 'disconnect', ->

  everyone.now.receive_lost_player @now.user