const bleno = require("bleno")
const {Route} = require("../route")
const coordinator = require("../coordinator").getInstance()

const {characteristics:{routeUpload}} = require("./bleConstants.json")

let route_upload_characteristic = new bleno.Characteristic({
  uuid: routeUpload.uuid, // or 'fff1' for 16-bit
  properties: [ "write" ], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  onWriteRequest: function(data, offset, withoutResponse, callback) {
    console.log("Write Request")
    console.log("Data: ", data)
    console.log("Offset: ", offset)
    console.log("WithoutResponse: ", withoutResponse)
    // Hoping it works
    let route = new Route()
    if (route.decode_data(data)) {
      coordinator.registerNewRoute(route)
      callback(bleno.Characteristic.RESULT_SUCCESS)
    } else {
      callback(bleno.Characteristic.RESULT_INVALID_ATTRIBUTE_LENGTH)
    }
  }

})

module.exports = route_upload_characteristic
