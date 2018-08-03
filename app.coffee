http = require 'http'
path = require 'path'
bodyparser = require 'body-parser'
express = require 'express'
mongoose = require 'mongoose'

Message = require './schema/Message.coffee'

app = express()


mongoose.connect 'mongodb://localhost:27017/people',{ useNewUrlParser: true}, (err) ->
	if err
		console.error err
	else
		console.log 'success!'

app.use bodyparser()

app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'pug'

app.get '/', (req, res, next) ->
	Message.find {}, (err, msgs) ->
		throw err if err
		data =
			messages: msgs
		res.render 'index', data

app.get '/update', (req, res, next) ->
	res.render 'update'

app.post '/update', (req, res, next) ->

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