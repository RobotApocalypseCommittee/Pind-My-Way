const {GeoCoord} = require("./GeoCoords")
const GPS = require("gps")
const SerialPort = require("serialport")
const Readline = SerialPort.parsers.Readline
const EventEmitter = require("events")

class GPSManager extends EventEmitter {
  constructor(port, rate) {
    super()
    this.ser = new SerialPort(port, {baudRate: rate})
    const parser = this.ser.pipe(new Readline({ delimiter: '\r\n' }))

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
          this.fixed = true;
          this.emit("fix")
        }

      }
    })
    parser.on('data', (data)=>{
      this.gps.update(data)
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
