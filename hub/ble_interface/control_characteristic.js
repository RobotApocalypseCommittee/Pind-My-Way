var util = require('util');

var bleno = require("bleno")
const coordinator = require("../coordinator").getInstance()
const bleConstants = require("./bleConstants")

var BlenoCharacteristic = bleno.Characteristic;

class ControlCharacteristic {
  constructor() {
    ControlCharacteristic.super_.call(this, {
      uuid: bleConstants.characteristics.control.uuid,
      properties: ['write'],
      value: null
    });
  }

  onWriteRequest(data, offset, withoutResponse, callback) {
    // Map it to action
    let action = data.readUInt8(0)
    switch (action) {
      case 1:
        winston.info('ControlCharacteristic - Begin Following');
        coordinator.beginFollowing()
        break;
      case 2:
        winston.info('ControlCharacteristic - End Following');
        coordinator.endFollowing()
        break;
      case 3:
        winston.info('ControlCharacteristic - Manual Disconnect');
        bleno.disconnect();
        break;
      default:
        callback(this.RESULT_UNLIKELY_ERROR)
        return;
    }
    callback(this.RESULT_SUCCESS)
  }
}

util.inherits(ControlCharacteristic, BlenoCharacteristic)
module.exports = ControlCharacteristic;
