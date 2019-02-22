var util = require('util');

var bleno = require("bleno")
const coordinator = require("../coordinator").getInstance()
const {Route} = require("../route")
const bleConstants = require("./bleConstants")

var BlenoCharacteristic = bleno.Characteristic;

class RouteUploadCharacteristic {
  constructor() {
    RouteUploadCharacteristic.super_.call(this, {
      uuid: bleConstants.characteristics.routeUpload.uuid,
      properties: ['write'],
      value: null
    });
  }

  onWriteRequest(data, offset, withoutResponse, callback) {
    console.log("Received route:")
    console.log("Data: ", data)
    // Hoping it works
    let route = new Route()
    if (route.decode_data(data)) {
      coordinator.registerNewRoute(route)
      callback(bleno.Characteristic.RESULT_SUCCESS)
    } else {
      callback(bleno.Characteristic.RESULT_INVALID_ATTRIBUTE_LENGTH)
    }
  }
}

util.inherits(RouteUploadCharacteristic, BlenoCharacteristic)
module.exports = RouteUploadCharacteristic;
