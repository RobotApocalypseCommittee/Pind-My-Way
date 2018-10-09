const bleno = require("bleno")

const {characteristics: {unique_identify, settable_name}} = require("./bleConstants.json")
let config = require("../config.json")
const fs = require("fs")


let random_id_characteristic = new bleno.Characteristic({
  uuid: unique_identify.uuid, // or 'fff1' for 16-bit
  properties: ["read"], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  value: config.random_id, // optional static value, must be of type Buffer - for read only characteristics
  descriptors: [
    new bleno.Descriptor({
      uuid: "2901",
      value: unique_identify.description
    })
  ]

})

let name_characteristic = new bleno.Characteristic({
  uuid: settable_name.uuid, // or 'fff1' for 16-bit
  properties: ["read", "write"], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  descriptors: [
    new bleno.Descriptor({
      uuid: "2901",
      value: settable_name.description
    })
  ],
  onWriteRequest: function (data, offset, withoutResponse, callback) {
    if (offset) {
      callback(this.RESULT_ATTR_NOT_LONG)
    } else {

      config.assigned_name = data.toString()
      fs.writeFile("../config.json", JSON.stringify(config, null, 2), function (err) {
        if (err) return console.log(err)
        callback(this.RESULT_SUCCESS)
      });
    }
  },
  onReadRequest: function(offset, callback) {
    if (offset) {
      callback(this.RESULT_ATTR_NOT_LONG, null);
    }
    else {
      let data = Buffer.from(config.assigned_name)
      callback(this.RESULT_SUCCESS, data);
    }
  }

})

module.exports = {random_id_characteristic, name_characteristic}
