const config = require("./config")
const EventEmitter = require("events")
const winston = require("winston")
const {GeoStore} = require("./logging")
const {RoutePoint} = require("./route")
// Polls/second -> minimum ms per poll
const poll_period = 1000/config.pollRate;

class Coordinator extends EventEmitter {
  constructor(gps, glovesLink) {
    super()
    this.geostore = new GeoStore("geolog.json")
    this.route = null
    this.running = false
    this.gps = gps;
    this.gps.on("fix", ()=>{
      this.emit("statusUpdate", this.getStatus())
    })
    this.leds = glovesLink;
    this.leds.on("stateChange", ()=>{
      this.emit("statusUpdate", this.getStatus())
    })
    this.interval = null;
  }
  registerNewRoute(route) {
    this.route = route
    this.emit("statusUpdate", this.getStatus())
    // TODO: Gloves indicate successful load
  }

  beginFollowing() {
    if (this.isReady()) {
      this.currentPointID = 0
      // Init GPS etc
      this.running = true;
      this.lastLevel = 3;
      this.leds.signalNeutral()
      this.leds.signalData(0, Math.round((this.route.points[this.currentPointID].pollution/100)*5), 255, 255, 255)
      this.emit("statusUpdate", this.getStatus())
      this.interval = setInterval(() => this.updateFollowing(), poll_period)
      winston.info("Started following")
      winston.info("Next point", {point: this.route.points[this.currentPointID]})
    } else {
      winston.error("System not ready to begin following",  {sysstat: this.getStatus().toString(2)})
    }
  }

  updateFollowing() {
    let currDistance = this.gps.location.distanceFrom(this.route.points[this.currentPointID].loc)
    winston.verbose("Update Following", {currentPoint: this.currentPointID, currDistance})
    this.geostore.logLocation(this.gps.location.lat, this.gps.location.lon);
    if (currDistance < config.completedDistance) {
      winston.verbose("Near end, and moving away")
      // Near end, and moving away -> next point
      this.currentPointID += 1
      winston.info("Next point", {point: this.route.points[this.currentPointID]})
      if (this.currentPointID === this.route.points.length) {
        // End has been reached
        this.endFollowing(true)
        return;
      } else {
        if (this.route.points[this.currentPointID].pollution !== 0) {
          let pol = this.route.points[this.currentPointID].pollution
          let r = pol <= 20 ? 0 : 255
          let g = pol <= 20 ? 255 : (pol <= 50 ? 127 : 0)
          this.leds.signalData(0, Math.round((this.route.points[this.currentPointID].pollution / 100) * 5), r, g, 255)
        }
      }
    } else if (currDistance < config.stageDistances[2]) {
      // Within thresholds
      // Get the closest stage that we are currently in
      let level =  2 - config.stageDistances.findIndex(x=>x > currDistance)
      if (this.lastLevel !== level) {
        winston.silly("Notifying signal", {proximity: level})
        this.lastLevel = level
        this.leds.signalDirection(this.route.points[this.currentPointID].direction, level)
      }
      winston.verbose("Within thresholds", {proximity: level})
      this.geostore.logRoutePoint(RoutePoint.getUserFriendlyDirection(this.route.points[this.currentPointID].direction),
        this.route.points[this.currentPointID].loc.lat,
        this.route.points[this.currentPointID].loc.lon,
        "Turn " + RoutePoint.getUserFriendlyDirection(this.route.points[this.currentPointID].direction) + " with level " + level
        )
    } else {
      // TODO: Is there an indication of how far to go?
      winston.verbose("Doing nothing")
      if (this.lastLevel !== 3) {
        winston.silly("Notifying neutral")
        this.lastLevel = 3
        this.leds.signalNeutral()
      }

    }
  }


  endFollowing(success) {
    if (this.running) {
      winston.info("Following has ended")
      clearInterval(this.interval)
      this.running = false;
      this.leds.signalRelax()
      this.route = null;
      this.emit("statusUpdate", this.getStatus())
    } else {
      winston.error("Cannot end following when not already following.")
    }
  }

  isReady() {
    return (this.gps.fixed && this.route !== null && ! this.running)
  }

  getStatus() {
    // Bits in format(lowest first) [Left Glove Connected][Right Glove Connected][GPS Connected][Route Provided][Ready To Start][Running]
    return (this.leds.gloves.left !== null)
      | ((this.leds.gloves.right !== null) << 1)
      | (this.gps.fixed << 2)
      | ((this.route !== null) << 3)
      | (this.isReady() << 4)
      | (this.running << 5)
  }
}
let instance = null;
module.exports = {
  createCoordinator: (gps, glovesLink) => {
    instance = new Coordinator(gps, glovesLink)
    return instance
  },
  getInstance: () => instance
}
