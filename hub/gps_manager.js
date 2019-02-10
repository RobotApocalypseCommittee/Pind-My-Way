const {GeoCoord} = require("./GeoCoords")
const GPS = require("gps")
const SerialPort = require("serialport")
const EventEmitter = require("events")

class GPSManager extends EventEmitter {
  constructor(port, rate) {
    super()
    this.ser = new SerialPort.SerialPort(port, {
      baudrate: rate,
      parser: SerialPort.parsers.readline('\r\n')
    });
    this.gps = new GPS
    // Does the GPS have a fix?
    this.fixed = false

    this.current = new GeoCoord(0, 0);
    this.old = new GeoCoord(0, 0);
    this.gps.on("GGA", (data)=>{
      if (!(data.lat === null || data.lon === null)) {
        this.old = this.current
        this.current = new GeoCoord(data.lat, data.lon)
        if (!this.fixed) {
          this.emit("fix")
        }
        this.fixed = true;

      }
    })

    this.ser.on("data", (data)=>{
      this.gps.updatePartial(data)
    })
  }
  get location(){
    return this.current
  }
  get previousLocation() {
    return this.old
  }
}

class MockGPSManager extends EventEmitter {
  constructor(){
    super()
    // Does the GPS have a fix?
    this.fixed = false

    this.current = new GeoCoord(0, 0);
    this.old = new GeoCoord(0, 0);
    setTimeout(()=>this.emit("fix"), 1000);
  }
  get location(){
    return this.current
  }
  get previousLocation() {
    return this.old
  }
}

module.exports = {GPSManager, MockGPSManager}
