const bleno = require("bleno")
const {Route} = require("../route")
const coordinator = require("../coordinator")

const {characteristics:{control}} = require("./bleConstants.json")

let control_characteristic = new bleno.Characteristic({
  uuid: control.uuid, // or 'fff1' for 16-bit
  properties: [ "write" ], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  onWriteRequest: function(data, offset, withoutResponse, callback) {
    console.log("Write Request")
    console.log("Data: ", data)
    console.log("Offset: ", offset)
    console.log("WithoutResponse: ", withoutResponse)
    if (data.length !== 1) {
      callback(bleno.Characteristic.RESULT_INVALID_ATTRIBUTE_LENGTH)
    } else {
      // Map it to action
      let action = data.getUint8(0)
      switch (action) {
        case 1: coordinator.beginFollowing()
          break;
        case 2: coordinator.endFollowing()
          break;
        default:
          callback(bleno.Characteristic.RESULT_UNLIKELY_ERROR)
          return;
      }
      callback(bleno.Characteristic.RESULT_SUCCESS)
    }
  },
  descriptors: [
    new bleno.Descriptor({
      uuid: "2901",
      value: control.description
    })
  ]

})

module.exports = control_characteristic
