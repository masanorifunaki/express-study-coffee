http = require 'http'
path = require 'path'
bodyParser = require 'body-parser'
express = require 'express'
mongoose = require 'mongoose'
fileUpload = require 'express-fileupload'

Message = require './schema/Message.coffee'

app = express()


mongoose.connect 'mongodb://localhost:27017/people',{ useNewUrlParser: true}, (err) ->
  if err
    console.error err
  else
    console.log 'success!'

app.use bodyParser()

app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'pug'

app.use '/image', express.static path.join __dirname, 'image'

app.get '/', (req, res, next) ->
  Message.find {}, (err, msgs) ->
    throw err if err
    data =
      messages: msgs
    res.render 'index', data

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