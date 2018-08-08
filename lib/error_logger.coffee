winston = require 'winston'

Logger = () ->
  winston.add winston.transports.File,
    filename: 'log/error.log'
    maxsize: 1048576
    level: 'error'

module.exports = new Logger()