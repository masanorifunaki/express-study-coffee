http = require 'http'
express = require 'express'
path = require 'path'
bodyParser = require 'body-parser'
mongoose = require 'mongoose'
fileUpload = require 'express-fileupload'
passport = require 'passport'
GitHubStrategy = require('passport-github2').Strategy
session = require 'express-session'
MongoStore = require('connect-mongo')(session)
helmet = require 'helmet'
csrf = require 'csurf'
moment = require 'moment-timezone'

moment.tz.setDefault 'Asia/Tokyo'

log = require './lib/error_logger'

User = require './schema/User.coffee'
Message = require './schema/Message.coffee'

app = express()

csrfProtection = csrf()

gitHubConfig =
  clientID: process.env.GITHUB_CLIENT_ID
  clientSecret: process.env.GITHUB_CLIENT_SECRET
  callbackURL: process.env.CALL_BACK_URL || 'http://localhost:3000/auth/github/callback'

passport.serializeUser (user, done) ->
  done null, user

passport.deserializeUser (id, done) ->
  User.findOne _id: id._id, (err, user) ->
    done null, user

mongoose.connect process.env. MONGODB_URI || 'mongodb://localhost:27017/people',{ useNewUrlParser: true}, (err) ->
  if err
    console.error err
  else
    console.log 'success!'

checkAuth = (req, res, next) ->
  if req.isAuthenticated()
    next()
  else
    res.redirect '/auth/github'

app.use helmet()
app.use bodyParser()

app.use session
  secret: 'HogeFuga'
  # 変更があった場合のみセッションを更新する
  resave: false
  # セッションに何か保存されるまでストレージに保存しない
  saveUninitialized: false
  store: new MongoStore
    mongooseConnection: mongoose.connection
#    url: 'mongodb://localhost:27017/people'
    db: 'session'
    ttl: 14 * 24 * 60 * 60
#  cookie:
#    secure: true

app.use passport.initialize()
app.use passport.session()

app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'pug'

app.use '/image', express.static path.join __dirname, 'image'
app.use '/avatar', express.static path.join __dirname, 'avatar'
app.use '/css', express.static path.join __dirname, 'css'

passport.use new GitHubStrategy(gitHubConfig, (token, tokenSecret, profile, done) ->
  User.findOne github_profile_id: profile.id, (err, user) ->
    if err
      done err

    else if !user
      _user =
        username: profile.username
        github_profile_id: profile.id
        avatar_path: profile._json.avatar_url

      newUser = new User _user
      newUser.save (err) ->
        throw err if err
        done null, newUser

    else
      done null, user
)

app.get '/', (req, res, next) ->

  Message.find {}, (err, msgs) ->
    throw err if err
    data =
      messages: msgs
      user: if req.user then req.user else null
      moment: moment
    res.render 'index', data

app.get '/logout', (req, res, next) ->
  req.logout()
  res.redirect '/'

app.get '/auth/github', passport.authenticate('github', scope: ['user:email']), (req, res) ->

app.get '/auth/github/callback', passport.authenticate('github', { failureRedirect: '/' }), (req, res) -> res.redirect '/'

app.get '/update', csrfProtection, (req, res, next) ->
  data =
    csrf: req.csrfToken()
    user: req.user
  res.render 'update', data

app.post '/update',checkAuth, fileUpload(), csrfProtection, (req, res, next) ->
  if req.files && req.files.image

    image_path = "./image/#{req.files.image.name}"

    req.files.image.mv image_path, (err) ->
      throw err if err

      newMessage = new Message
        username: req.user.username
        avatar_path: req.user.avatar_path
        message: req.body.message
        image_path: image_path

      newMessage.save (err) ->
        throw err if err
        res.redirect '/'

  else
    newMessage = new Message
      username: req.user.username
      avatar_path: req.user.avatar_path
      message: req.body.message

    newMessage.save (err) ->
      throw err if err
      res.redirect '/'

app.use (req, res, next) ->
  err = new Error 'Not Found'
  err.status = 404
  data =
    status: err.status
  res.render 'error', data

app.use (err, req, res, next) ->
  log.error err
  switch err
    when err.code == 'EBADCSRFTOKEN'
      res.status 403
    else
      res.status err.status || 500
  data =
    message: err.message
    status: err.status || 500
  res.render 'error', data

server = http.createServer(app)
port = 3000
server.listen process.env.PORT || port, ->
  console.info "Listening on #{port}"