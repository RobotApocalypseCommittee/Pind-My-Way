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

    this._value = Buffer.from("0.0.2");
  }

  onReadRequest(offset, callback) {
    console.log('VersionCharacteristic - onReadRequest: value = ' + this._value.toString('hex'));

    callback(this.RESULT_SUCCESS, this._value);
  }
}

util.inherits(VersionCharacteristic, BlenoCharacteristic)
module.exports = VersionCharacteristic;
