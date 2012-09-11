express = require('express')
http = require('http')
path = require('path')

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
  app.use app.router
  app.use express.static(path.join(__dirname, 'public'))
  app.use express.errorHandler()

http.createServer(app).listen app.get('port')