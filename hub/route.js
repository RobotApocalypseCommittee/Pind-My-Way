const {GeoCoord} = require("./GeoCoords")
const winston = require("winston")

class RoutePoint {
  constructor(command, lat, lon) {
    this.direction = command
    this.loc = new GeoCoord(lat, lon)
    winston.silly("Command", {command})
    winston.silly("Location", {loc: this.loc})
  }
  toJSON() {
    return { point: this.point, direction: RoutePoint.getUserFriendlyDirection(this.direction)}
  }

  static getUserFriendlyDirection(angleIndication) {
    switch (angleIndication) {
      case 0:
        return "straight"
      case 1:
        return "bear right"
      case 2:
        return "turn right"
      case 3:
        return "u-turn right"
      case -1:
        return "bear left"
      case -2:
        return "turn left"
      case -3:
        return "u-turn left"
      case 4:

    }
  }

  static getAngleIndicationFromManeuver(maneuverID) {
    /* The angle indication is thus
       -1 0  1
        \ | /
     -2 - X - 2
        / | \
      -3  4  3
        */
    switch (maneuverID) {
      case 0:
        return 0
      case 1:
        return 1
      case 2:
        return 2
      case 3:
        return 2
      case 4:
        return 3
      case 5:
        return -3
      case 6:
        return -2
      case 7:
        return -2
      case 8:
        return -1
      case 17:
        return 1
      case 18:
        return -1
      case 33:
        // Roundabouts tricky
        return 2
      case 34:
        return -2
      default:
        return 0
    }
  }
}
class Route {
  // Represents a route, which is (essentially) a list of route points.
  constructor() {
    this.points = []
    this.buffer_complete = true
    // Nothing in buffer as of yet.
    this.input_buffer = Buffer.alloc(0)

  }

  add_point(route_point) {
    // Route point is instance of RoutePoint
    this.points.push(route_point)
  }

  decode_data(buf) {
    // Data from BLE connection about points.
    /* Format as it currently stands:
    0: Byte: The direction(at moment only left, right, forward, but might add bear)
    1: Double(64bit): The latitude of the point(Big Endian)
    9: Double(64bit): The longitude of the point(Big Endian
    17: END( next instruction starts)
     */
    if (!this.buffer_complete) {
      // Add dregs from last call.
      buf = Buffer.concat([this.input_buffer, buf])
    }
    let offset = 0
    while (offset < buf.length) {
      let cbuf = buf.slice(offset, offset+18)
      // Read a byte at position 0
      let bearing = cbuf.readUInt8(0)
      let maneuver = cbuf.readUInt8(1)
      winston.silly("Maneuver", {maneuver: maneuver})
      let command = RoutePoint.getAngleIndicationFromManeuver(maneuver)
      let lat = cbuf.readDoubleLE(2)
      let lon = cbuf.readDoubleLE(10)
      this.add_point(new RoutePoint(command, lat, lon))
      offset += 18
    }
    if (offset !== buf.length) {
      this.buffer_complete = false
      this.input_buffer = buf.slice(offset)
    } else {
      this.buffer_complete = true
    }
    return this.buffer_complete
  }
  finalise() {
    // Odd google maps behaviour
    for (let i = 0; i < this.points.length - 1; i++) {
        this.points[i].direction = this.points[i+1].direction
    }
    this.points[this.points.length - 1].direction = 0
  }

}

module.exports = {Route, RoutePoint}
