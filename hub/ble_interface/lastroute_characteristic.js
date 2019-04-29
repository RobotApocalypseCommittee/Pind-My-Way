var util = require('util');

var bleno = require('bleno');
const coordinator = require("../coordinator").getInstance()
const bleConstants = require("./bleConstants")
const winston = require("winston")

var BlenoCharacteristic = bleno.Characteristic;

class LastRouteCharacteristic {
  constructor() {
    LastRouteCharacteristic.super_.call(this, {
      uuid: bleConstants.characteristics.lastRoute.uuid,
      properties: ['read'],
      value: null
    });


  }

  onReadRequest(offset, callback) {
    let {speed, distance, time, valid} = coordinator.routeresstore.obj;
    let data = Buffer.alloc(17);
    data.writeUInt8(valid ? 1 : 0, 0);
    data.writeUInt32LE(distance, 1);
    data.writeUInt32LE(time, 5);
    data.writeDoubleLE(speed, 9);
    winston.verbose('LastRouteCharacteristic - onReadRequest: value = ' + data.toString('hex'));

    callback(this.RESULT_SUCCESS, data);
  }
}

util.inherits(LastRouteCharacteristic, BlenoCharacteristic)
module.exports = LastRouteCharacteristic;
