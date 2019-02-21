let config = require("../config.json")

var util = require('util');

var bleno = require("bleno")
const coordinator = require("../coordinator").getInstance()
const bleConstants = require("./bleConstants")

var BlenoCharacteristic = bleno.Characteristic;

class StatusCharacteristic {
  constructor() {
    StatusCharacteristic.super_.call(this, {
      uuid: bleConstants.characteristics.status.uuid,
      properties: ['read', 'notify'],
      value: null
    });

    this._value = Buffer.from([coordinator.getStatus()]);
    this._updateValueCallback = null;

    coordinator.on("statusUpdate", (newStatus)=>{
      this._value = Buffer.from([coordinator.getStatus()]);
      if (this._updateValueCallback) {
        console.log("StatusCharacteristic - notifying: newStatus = " + newStatus.toString('hex'));
        this._updateValueCallback(this._value);
      }
    })
  }

  onReadRequest(offset, callback) {
    console.log('StatusCharacteristic - onReadRequest: value = ' + this._value.toString('hex'));

    callback(this.RESULT_SUCCESS, this._value);
  }

  onSubscribe(maxValueSize, updateValueCallback) {
    console.log('StatusCharacteristic - onSubscribe');

    this._updateValueCallback = updateValueCallback;
  }

  onUnsubscribe() {
    console.log('StatusCharacteristic - onUnsubscribe');

    this._updateValueCallback = null;
  }
}

util.inherits(StatusCharacteristic, BlenoCharacteristic)
module.exports = StatusCharacteristic;
