const bleno = require("bleno")
const bleConstants = require("./bleConstants.json")

let route_upload_characteristic = new bleno.Characteristic({
  uuid: bleConstants.routeUploadCharacteristic, // or 'fff1' for 16-bit
  properties: [ "write" ], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  onWriteRequest: function(data, offset, withoutResponse, callback) {
    console.log("Write Request")
    console.log("Data: ", data)
    console.log("Offset: ", offset)
    console.log("WithoutResponse: ", withoutResponse)
    callback(bleno.Characteristic.RESULT_SUCCESS)
  }

})

module.exports = route_upload_characteristic
