http = require 'http'
express = require 'express'
path = require 'path'
bodyParser = require 'body-parser'
mongoose = require 'mongoose'
fileUpload = require 'express-fileupload'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy
session = require 'express-session'

User = require './schema/User.coffee'
Message = require './schema/Message.coffee'

app = express()

mongoose.connect 'mongodb://localhost:27017/people',{ useNewUrlParser: true}, (err) ->
  if err
    console.error err
  else
    console.log 'success!'

app.use bodyParser()

app.use session { secret: 'HogeFuga'}
app.use passport.initialize()
app.use passport.session()

app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'pug'

app.use '/image', express.static path.join __dirname, 'image'
app.use '/avatar', express.static path.join __dirname, 'avatar'

app.get '/', (req, res, next) ->
  Message.find {}, (err, msgs) ->
    throw err if err
    data =
      messages: msgs
      user: if req.session && req.session.user then req.session.user else null
    res.render 'index', data

app.get '/signin', (req, res, next) ->
  res.render 'signin'

app.post '/signin', fileUpload(), (req, res, next) ->
  avatar = req.files.avatar
  avatar_path = "./avatar/#{avatar.name}"
  avatar.mv "#{avatar_path}", (err) ->
    throw err if err
    newUser = new User
      username: req.body.username
      password: req.body.password
      avatar_path: avatar_path

    newUser.save (err) ->
      throw err if err
      res.redirect '/'

app.get '/login', (req, res, next) ->
  res.render 'login'

app.post '/login', passport.authenticate('local'), (req, res, next) ->
  User.findOne {_id: req.session.passport.user }, (err, user) ->
    res.redirect '/login' if err || !req.session

    req.session.user =
      username: user.username
      avatar_path: user.avatar_path

    res.redirect '/'

passport.use new LocalStrategy((username, password, done) ->
  User.findOne {username: username}, (err, user) ->
    done err if err
    done null, false, {message: 'Incorrect username.'} if !user
    done null, false, {message: 'Incorrect password.'} if user.password != password
    done null, user
)

passport.serializeUser (user, done) ->
  done null, user._id

passport.deserializeUser (id, done) ->
  User.findOne { _id: id }, (err, user) ->
    done err, user

app.get '/update', (req, res, next) ->
  res.render 'update'

app.post '/update', fileUpload(), (req, res, next) ->

  if req.files && req.files.image
    image_path = "./image/#{req.files.image.name}"
    req.files.image.mv image_path, (err) ->
      throw err if err
      newMessage = new Message
        username: req.body.username
        message: req.body.message
        image_path: image_path

      newMessage.save (err) ->
        throw err if err
        res.redirect '/'
  else
    newMessage = new Message
      username: req.body.username
      message: req.body.message

    newMessage.save (err) ->
      throw err if err
      res.redirect '/'


server = http.createServer(app)
port = 3000
server.listen port, ->
  console.info "Listening on #{port}"