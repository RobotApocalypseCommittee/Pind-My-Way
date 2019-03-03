const {GeoCoord} = require("./GeoCoords")
const GPS = require("gps")
const SerialPort = require("serialport")
const Readline = SerialPort.parsers.Readline
const EventEmitter = require("events")

class GPSManager extends EventEmitter {
  constructor(port) {
    super()
    // Start at 9600 baud
    this.ser = new SerialPort(port, {baudRate: 9600})
    // Configure
    // 5Hz transmitted updates
    this.ser.write("$PMTK220,200*2C\r\n")
    // Get new location at 5Hz
    this.ser.write("$PMTK300,200,0,0,0,0*2F\r\n")
    // Set the packets we want
    this.ser.write("$PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0*28\r\n")
    // Boost baud to 57600
    this.ser.write("$PMTK251,57600*2C\r\n")
    this.ser.drain(()=> {
      this.ser.update({baudRate:57600}, ()=>{
        this.ser.flush()
        const parser = this.ser.pipe(new Readline({ delimiter: '\r\n' }))
      })
    })
    const parser = this.ser.pipe(new Readline({ delimiter: '\r\n' }))

    this.gps = new GPS
    // Does the GPS have a fix?
    this.fixed = false

    this.current = new GeoCoord(0, 0);
    this.old = new GeoCoord(0, 0);
    let m_callback = (data)=>{
      if (!(data.lat === null || data.lon === null)) {
        this.old = this.current
        this.current = new GeoCoord(data.lat, data.lon)
        if (!this.fixed) {
          this.fixed = true;
          this.emit("fix")
        }
      }
    }
    this.gps.on("GGA", m_callback)
    this.gps.on("RMC", m_callback)
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
