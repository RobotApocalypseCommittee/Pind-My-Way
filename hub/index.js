const yargs = require("yargs")
const {GPSManager, MockGPSManager} = require("./gps_manager")
const GlovesLink = require("./led_interface")
const config = require("./config")
const {setupLogging} = require("./logging")
const winston = require("winston")

setupLogging(config.loggingLevel)

let argv = yargs.config(config).command('run [port] [baudrate]', 'Run the full system', {}, (argv) => {
  const coordinator = require("./coordinator").createCoordinator(new GPSManager(argv.port, argv.baudrate), new GlovesLink())
  require("./ble_interface")
  winston.info("Running...")
}).command('gps [port] [baudrate]', 'Test a GPS controller', {}, (argv) => {
  const gps = new GPSManager(argv.port, argv.baudrate)
  gps.on("fix", () => {
    winston.info("GPS Fixed")
  })
  setInterval(() => winston.silly("Location", {point: gps.current}), 1000)
}).command('bluetest', 'Test the bluetooth system - mocks GPS', {}, (argv) => {
  const coordinator = require("./coordinator").createCoordinator(new MockGPSManager(), new GlovesLink())
  winston.info("Running...")
  coordinator.on("statusUpdate", (status) => {
    winston.verbose("New Status:"+status.toString(2));
  })
  require("./ble_interface")
}).command('walktest [walk] [port] [baudrate]', 'Test on a pre-set walk', {}, (argv) => {
  let buf = Buffer.from(argv.walk, 'hex')
  const coordinator = require("./coordinator").createCoordinator(new GPSManager(argv.port, argv.baudrate), new GlovesLink())
  require("./ble_interface")
  winston.info("Running...")
  const {Route} = require("./route")
  let route = new Route()
  if (route.decode_data(buf)) {
    route.finalise()
    coordinator.registerNewRoute(route)
    winston.info("Successfully registered route - waiting for fix.")
    if (coordinator.gps.fixed) {
      winston.info("GPS Fixed - Attempting to begin")
      coordinator.beginFollowing()

    } else {
    coordinator.gps.on("fix", ()=> {
      winston.info("GPS Fixed - Attempting to begin")
      coordinator.beginFollowing()
      }
    ) }
  } else {
    winston.error("Data provided was not correctly formed.")
  }
})
  .help('h')
  .alias('h', 'help')
  .argv;
