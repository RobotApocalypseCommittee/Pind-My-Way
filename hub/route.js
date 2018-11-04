const {GeoCoord} = require("./GeoCoords")

class RoutePoint {
  constructor(command, lat, lon) {
    if (typeof command === 'number') {
      switch (command) {
        case 0: command = "forward"; break;
        case 1: command = "left"; break;
        case 2: command = "right"; break;
        case 3: command = "reverse"; break;
        default: throw `Unknown command ${command}`;
      }
    }
    this.direction = command
    this.loc = new GeoCoord(lat, lon)
  }
}
class Route {
  // Represents a route, which is (essentially) a list of route points.
  constructor() {
    this.points = []
    this.buffer_complete = true
    // Space for one message
    this.input_buffer = Buffer.alloc(17)

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
    while (offset+16 < buf.length) {
      let cbuf = buf.slice(offset, offset+17)
      // Read a byte at position 0
      let command = cbuf.readUInt8(0)
      let lat = cbuf.readDoubleLE(1)
      let lon = cbuf.readDoubleLE(9)
      this.add_point(new RoutePoint(command, lat, lon))
      offset += 17
    }
    if (offset+1 !== buf.length) {
      this.buffer_complete = false
      this.input_buffer = buf.slice(offset)
    } else {
      this.buffer_complete = true
    }
    return this.buffer_complete
  }

}

module.exports = {Route, RoutePoint}
