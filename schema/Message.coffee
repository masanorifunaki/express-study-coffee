mongoose = require 'mongoose'

Message = mongoose.Schema
  username: String
  message: String
  data:
    type: Date
    default: new Date()
  image_path: String

module.exports = mongoose.model 'Message', Message
