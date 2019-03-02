const fs = require("fs")
const winston = require("winston")

function printLog({timestamp, message, level, metadata}) {
  return `[${timestamp}] ${level}: ${message} ${JSON.stringify(metadata)}`;
}

function setupLogging(level) {
  const mainFormat = winston.format.combine(
    winston.format.splat(),
    winston.format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    winston.format.errors({stack: true}),
    winston.format.metadata({fillExcept: ['timestamp', 'message', 'level']}),
    winston.format.printf(printLog)
  )

  winston.add(
    new winston.transports.File({
      filename: 'route_debug.log',
      level: level,
      format: mainFormat
    })
  ).add(
    new winston.transports.Console({
      level: level
      format: winston.format.combine(
        winston.format.colorize(),
        mainFormat
      )
    })
  )
}

class GeoStore {
  constructor(filename) {
    this.filename = filename
    this.obj = {loggedPoints: [], routePoints: []}
    this.save()
    setInterval(()=>this.save(), 5000)
  }
  load() {
    this.obj = JSON.parse(fs.readFileSync(this.filename, 'utf8'));
  }
  save() {
    fs.writeFileSync(this.filename, JSON.stringify(this.obj), 'utf8')
  }
  logLocation(lat, lon) {
    this.obj.loggedPoints.push({lat: lat, lon: lon, timestamp: Date.now()})
  }
  logRoutePoint(name, lat, lon, message) {
    this.obj.routePoints.push({lat, lon, name, message, timestamp: Date.now()})
  }
}

module.exports = {
  setupLogging,
  GeoStore
}
