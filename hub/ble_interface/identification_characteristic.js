var util = require('util');
const fs = require('fs');
const path = require('path');

var bleno = require('bleno');
const bleConstants = require("./bleConstants")
const winston = require("winston")


var BlenoCharacteristic = bleno.Characteristic;

class IdentificationCharacteristic {
  constructor() {
    IdentificationCharacteristic.super_.call(this, {
      uuid: bleConstants.characteristics.settable_name.uuid,
      properties: ['read', 'write'],
      value: null
    });
    this._configPath = path.join(__dirname, '..', 'config.json')
    this._value = Buffer.alloc(0)
    this._updateName()
  }

  onReadRequest(offset, callback) {
    winston.verbose('IdentificationCharacteristic - onReadRequest: value = ' + this._value.toString());

    callback(this.RESULT_SUCCESS, this._value);
  }
  onWriteRequest(data, offset, withoutResponse, callback) {
    winston.verbose('IdentificationCharacteristic - onWriteRequest: value = ' + this._value.toString());
    this._writeAssignedName(data.toString());
    this._updateName();
    callback(this.RESULT_SUCCESS)
  }
  _updateName() {
    fs.readFile(this._configPath, 'utf8',(err, contents)=> {
      if (err) throw err;
      this._value = Buffer.from(JSON.parse(contents).assignedName);
      winston.verbose('IdentificationCharacteristic - Read JSON')
    })
  }
  _writeAssignedName(newName) {
    fs.readFile(this._configPath, 'utf8',(err, contents)=>{
      if (err) throw err;
      let obj = JSON.parse(contents)
      obj.assignedName = newName
      fs.writeFile(this._configPath, JSON.stringify(obj), (err)=>{
        if (err) throw err;
        winston.verbose('IdentificationCharacteristic - Wrote JSON')
      })
    })
  }
}

util.inherits(IdentificationCharacteristic, BlenoCharacteristic)
module.exports = IdentificationCharacteristic;
