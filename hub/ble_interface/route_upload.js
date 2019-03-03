var util = require('util');

var bleno = require("bleno")
const coordinator = require("../coordinator").getInstance()
const {Route} = require("../route")
const bleConstants = require("./bleConstants")
const winston = require("winston")

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
    winston.info("Received route:")
    winston.info("Data: " + data.toString())
    // Hoping it works
    let route = new Route()
    if (route.decode_data(data)) {
      route.finalise()
      coordinator.registerNewRoute(route)
      callback(bleno.Characteristic.RESULT_SUCCESS)
    } else {
      callback(bleno.Characteristic.RESULT_INVALID_ATTRIBUTE_LENGTH)
    }
  }
}

util.inherits(RouteUploadCharacteristic, BlenoCharacteristic)
module.exports = RouteUploadCharacteristic;
