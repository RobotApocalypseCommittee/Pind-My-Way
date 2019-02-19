const bleno = require("bleno")
const bleConstants = require("./bleConstants.json")

const versionCharacteristic = require("./version_characteristic")
const routeUploadCharacteristic = require("./route_upload")
const {name_characteristic, random_id_characteristic} = require("./identification_characteristic")
const statusCharacteristic = require("./status_characteristic")
const controlCharacteristic = require("./control_characteristic")

bleno.on('stateChange', function(state) {
  console.log('on -> stateChange: ' + state);

  if (state === 'poweredOn') {
    bleno.startAdvertising(bleConstants.deviceName, [bleConstants.primaryService]);
  } else {
    bleno.stopAdvertising();
  }
});
bleno.on('advertisingStart', function(error) {
  console.log('on -> advertisingStart: ' + (error ? 'error ' + error : 'success'));
  let primaryService = new bleno.PrimaryService({
    uuid: bleConstants.primaryService, // or 'fff0' for 16-bit
    characteristics: [
      versionCharacteristic,
      routeUploadCharacteristic,
      random_id_characteristic,
      name_characteristic,
      statusCharacteristic,
      controlCharacteristic
    ]
  })
  if (!error) {
    bleno.setServices([
      primaryService
    ]);
  }
});

bleno.on('accept', (cA)=>console.log("Accept: ", cA));
bleno.on('disconnect', (cA)=>console.log("Disconnect: ", cA));


