const bleno = require("bleno")

let version_characteristic = new bleno.Characteristic({
  uuid: 'd0668495159f405ecebe4014a716de2e1', // or 'fff1' for 16-bit
  properties: [ "read" ], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  value: Buffer.from("0.0.1"), // optional static value, must be of type Buffer - for read only characteristics
  descriptors: [
    new bleno.Descriptor({
      uuid: '2901',
      value: 'The platform\'s version' // static value, must be of type Buffer or string if set
    })
  ]
})

module.exports = version_characteristic
