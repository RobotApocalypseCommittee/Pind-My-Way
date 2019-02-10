const config = require("./config")
const EventEmitter = require("events")

// Polls/second -> minimum ms per poll
const poll_period = 1000/config.pollRate;

class Coordinator extends EventEmitter {
  constructor(gps, glovesLink) {
    super()
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
let instance = null;
module.exports = {
  createCoordinator: (gps, glovesLink) => {
    instance = new Coordinator(gps, glovesLink)
    return instance
  },
  getInstance: () => instance
}
