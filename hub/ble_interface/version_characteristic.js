var util = require('util');

var bleno = require('bleno');
const bleConstants = require("./bleConstants")

var BlenoCharacteristic = bleno.Characteristic;

class VersionCharacteristic {
  constructor() {
    VersionCharacteristic.super_.call(this, {
      uuid: bleConstants.characteristics.version.uuid,
      properties: ['read'],
      value: null
    });

    this._value = new Buffer(0);
    this._updateValueCallback = null;
  }

  onReadRequest(offset, callback) {
    console.log('EchoCharacteristic - onReadRequest: value = ' + this._value.toString('hex'));

    callback(this.RESULT_SUCCESS, this._value);
  }
}

util.inherits(VersionCharacteristic, BlenoCharacteristic)
module.exports = VersionCharacteristic;
