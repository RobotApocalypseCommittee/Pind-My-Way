const bleno = require("bleno")


const versionCharacteristic = require("./version_characteristic")

bleno.on('stateChange', function(state) {
  console.log('on -> stateChange: ' + state);

  if (state === 'poweredOn') {
    bleno.startAdvertising('pimw', ['9540']);
  } else {
    bleno.stopAdvertising();
  }
});
bleno.on('advertisingStart', function(error) {
  console.log('on -> advertisingStart: ' + (error ? 'error ' + error : 'success'));
  let primaryService = new bleno.PrimaryService({
    uuid: '9540', // or 'fff0' for 16-bit
    characteristics: [
      versionCharacteristic
    ]
  })
  console.log(primaryService)
  if (!error) {
    bleno.setServices([
      primaryService
    ]);
  }
});

