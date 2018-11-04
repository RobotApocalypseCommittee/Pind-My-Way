const FollowingConfig = require("./following_config")

// Polls/second -> minimum ms per poll
const poll_period = 1000/FollowingConfig.maxPollRate

class Coordinator {
  constructor() {
    this.route = null
    this.running = false
  }
  registerNewRoute(route) {
    this.route = route
    // TODO: Gloves indicate successful load
  }

  beginFollowing() {
    this.currentPointID = 0
    this.getCurrentLocation().then(
      (loc) => {
        // TODO: Gloves indicate beginning
        this.last_poll_time = Date.now()
        this.updateFollowing(loc)
      }
    )
  }

  updateFollowing(loc) {
    if (this.currentPointID === this.route.points.length) {
      // TODO: Gloves indicate finish
    } else {
      // TODO: Stuff
      
      this.getCurrentLocation().then(
        (loc)=> {
          const n = poll_period - (Date.now() - this.last_poll_time)
          this.last_poll_time = Date.now()
          if (n>0) {
            setTimeout(()=>this.updateFollowing(loc), n)
          } else {
            this.updateFollowing(loc)
          }
        }
      )
    }
  }

  getCurrentLocation() {
    // TODO: Read GPS
    return new Promise()
  }
}

module.exports = new Coordinator();
