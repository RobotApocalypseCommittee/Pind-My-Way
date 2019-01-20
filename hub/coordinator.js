const FollowingConfig = require("./following_config")
const GPSManager = require("./gps_manager")
const GlovesLink = require("./led_interface")
const EventEmitter = require("events")

// Polls/second -> minimum ms per poll
const poll_period = 1000/FollowingConfig.maxPollRate

class Coordinator extends EventEmitter {
  constructor() {
    super()
    this.route = null
    this.running = false
    this.gps = new GPSManager()
    this.gps.on("fix", ()=>{
      this.emit("statusUpdate", this.getStatus())
    })
    this.leds = new GlovesLink()
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
    this.currentPointID = 0
    // Init GPS etc
    this.running = true;
    this.emit("statusUpdate", this.getStatus())
    this.interval = setInterval(()=>this.updateFollowing(), poll_period)
  }

  updateFollowing() {
    let prevDistance = this.gps.previousLocation.distanceFrom(this.route.points[this.currentPointID+1].loc)
    let currDistance = this.gps.location.distanceFrom(this.route.points[this.currentPointID+1].loc)
    if (prevDistance < FollowingConfig.completedDistance && prevDistance < currDistance) {
      // Near end, and moving away -> next point
      this.currentPointID += 1
      if (this.currentPointID + 1 === this.route.points.length) {
        // End has been reached
        this.endFollowing(true)
        return;
      }
    } else if (currDistance < FollowingConfig.stageDistances[0]) {
      // Within thresholds
      // Get the closest stage that we are currently in
      let level = FollowingConfig.stageDistances.slice().reverse().findIndex(x=>x > currDistance)
      this.leds.signalDirection(this.route.points[this.currentPointID+1].direction, level)
    } else {
      // TODO: Is there an indication of how far to go?
    }
  }


  endFollowing(success) {
    if (this.running) {
      clearInterval(this.interval)
      this.running = false;
      this.route = null;
      this.emit("statusUpdate", this.getStatus())
    }
  }

  isReady() {
    return (this.gps.fixed && this.route !== null && ! this.running)
  }

  getStatus() {
    // Bits in format(lowest first) [Left Glove Connected][Right Glove Connected][GPS Connected][Route Provided][Ready To Start][Running]
    return (this.leds.gloves.left !== null)
      | (this.leds.gloves.right !== null << 1)
      | (this.gps.fixed << 2)
      | (this.route !== null << 3)
      | (this.isReady() << 4)
      | (this.running << 5)
  }
}

module.exports = new Coordinator();
