mongoose = require 'mongoose'

User = mongoose.Schema
  username: String
  password: String
  date:
    type: Date
    default: new Date()
  avatar_path: String
  github_profile_id: String

module.exports = mongoose.model 'User', User