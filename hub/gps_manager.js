const {GeoCoord} = require("./GeoCoords")
const GPS = require("gps")
const SerialPort = require("serialport")
const EventEmitter = require("events")

class GPSManager extends EventEmitter {
  constructor(port, rate, rollingAvg){
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
        this.current = new GeoCoord(dats.lat, data.lon)
        this.fixed = true;
        this.emit("fix")
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

module.exports = GPSManager
