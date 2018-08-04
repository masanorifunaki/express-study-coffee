mongoose = require 'mongoose'

User = mongoose.Schema
  username: String
  password: String
  data:
    type: Date
    default: new Date()
  avatar_path: String

module.exports = mongoose.model 'User', User