const bleno = require("bleno")

const {characteristics:{routeUpload}} = require("./bleConstants.json")

let route_upload_characteristic = new bleno.Characteristic({
  uuid: routeUpload.uuid, // or 'fff1' for 16-bit
  properties: [ "write" ], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  onWriteRequest: function(data, offset, withoutResponse, callback) {
    console.log("Write Request")
    console.log("Data: ", data)
    console.log("Offset: ", offset)
    console.log("WithoutResponse: ", withoutResponse)
    callback(bleno.Characteristic.RESULT_SUCCESS)
  },
  descriptors: [
    new bleno.Descriptor({
      uuid: "2901",
      value: routeUpload.description
    })
  ]

})

module.exports = route_upload_characteristic
