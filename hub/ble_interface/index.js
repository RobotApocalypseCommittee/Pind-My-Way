const bleno = require("bleno")

const bleConstants = require("./bleConstants.json")

var BlenoPrimaryService = bleno.PrimaryService;

var VersionCharacteristic = require("./version_characteristic")

console.log('bleno - echo');

bleno.on('stateChange', function(state) {
  console.log('on -> stateChange: ' + state);

  if (state === 'poweredOn') {
    bleno.startAdvertising('pmw', [bleConstants.primaryService]);
  } else {
    bleno.stopAdvertising();
  }
});

bleno.on('advertisingStart', function(error) {
  console.log('on -> advertisingStart: ' + (error ? 'error ' + error : 'success'));

  if (!error) {
    bleno.setServices([
      new BlenoPrimaryService({
        uuid: bleConstants.primaryService,
        characteristics: [
          new VersionCharacteristic()
        ]
      })
    ]);
  }
});
