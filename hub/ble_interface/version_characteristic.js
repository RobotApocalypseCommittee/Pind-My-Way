const bleno = require("bleno")

const {characteristics:{version}} = require("./bleConstants.json")

let version_characteristic = new bleno.Characteristic({
  uuid: version.uuid, // or 'fff1' for 16-bit
  properties: [ "read" ], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  value: Buffer.from("0.0.1"), // optional static value, must be of type Buffer - for read only characteristics
  descriptors: [
    new bleno.Descriptor({
      uuid: "2901",
      value: version.description
    })
  ]

})

module.exports = version_characteristic
