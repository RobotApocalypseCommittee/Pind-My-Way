const bleno = require("bleno")

const bleConstants = require("./bleConstants.json")
const winston = require("winston")

var BlenoPrimaryService = bleno.PrimaryService;

var VersionCharacteristic = require("./version_characteristic")
var StatusCharacteristic = require("./status_characteristic")
var ControlCharacteristic = require("./control_characteristic")
var IdentificationCharacteristic = require("./identification_characteristic")
var RouteUploadCharacteristic = require("./route_upload")


winston.info('bleno - echo');

bleno.on('stateChange', function(state) {
  winston.info('on -> stateChange: ' + state);

  if (state === 'poweredOn') {
    bleno.startAdvertising('pmw', [bleConstants.primaryService]);
  } else {
    bleno.stopAdvertising();
  }
});

bleno.on('advertisingStart', function(error) {
  winston.info('on -> advertisingStart: ' + (error ? 'error ' + error : 'success'));

  if (!error) {
    bleno.setServices([
      new BlenoPrimaryService({
        uuid: bleConstants.primaryService,
        characteristics: [
          new VersionCharacteristic(),
          new StatusCharacteristic(),
          new ControlCharacteristic(),
          new RouteUploadCharacteristic(),
          new IdentificationCharacteristic()
        ]
      })
    ]);
  }
});
