const yargs = require("yargs")
const {GPSManager, MockGPSManager} = require("./gps_manager")
const GlovesLink = require("./led_interface")
const config = require("./config")
let argv = yargs.config(config).command('run [port] [baudrate]', 'Run the full system', {}, (argv) => {
  const coordinator = require("./coordinator").createCoordinator(new GPSManager(argv.port, argv.baudrate), new GlovesLink())
  require("./ble_interface")
  console.log("Running...")
}).command('gps [port] [baudrate]', 'Test a GPS controller', {}, (argv) => {
  const gps = new GPSManager(argv.port, argv.baudrate)
  gps.on("fix", () => {
    console.log("GPS Fixed")
  })
  setTimeout(() => console.log("Location: ", gps.current.lat, gps.current.lon), 1000)
}).command('bluetest', 'Test the bluetooth system - mocks GPS', {}, (argv) => {
  const coordinator = require("./coordinator").createCoordinator(new MockGPSManager(), new GlovesLink())
  console.log("Running...")
  coordinator.on("statusUpdate", (status) => {
    console.log("New Status: ", status);
  })
  require("./ble_interface")
})
  .help('h')
  .alias('h', 'help')
  .argv;
