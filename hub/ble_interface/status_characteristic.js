const bleno = require("bleno")

const {characteristics: {status}} = require("./bleConstants.json")
let config = require("../config.json")
const coordinator = require("../coordinator").getInstance()


let status_characteristic = new bleno.Characteristic({
  uuid: status.uuid, // or 'fff1' for 16-bit
  properties: ["read", "notify"], // can be a combination of 'read', 'write', 'writeWithoutResponse', 'notify', 'indicate'
  onReadRequest: function(offset, callback) {
    if (offset) {
      callback(this.RESULT_ATTR_NOT_LONG, null);
    }
    else {
      let data = Buffer.from([coordinator.getStatus()])
      callback(this.RESULT_SUCCESS, data);
    }
  }
})

coordinator.on("statusUpdate", (newStatus)=> {
  if (status_characteristic.updateValueCallback) {
    status_characteristic.updateValueCallback(Buffer.from([newStatus]))
    console.log("[BLE] Notified status change")
  } else {
    console.log("[BLE] Could not notify.")
  }
})

module.exports = status_characteristic
