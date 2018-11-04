
const R = 6371e3; // metres

function radians(degrees) {
  return degrees * Math.PI / 180
}

function degrees(radians) {
  return radians * 180 / Math.PI
}

class GeoCoord {
  constructor(lat, lon) {
    this._lat = lat
    this._lon = lon
  }

  get lat() {
    // Latitude in degrees
    return this._lat
  }

  get lon() {
    // Latitude in degrees
    return this._lon
  }

  get φ() {
    // Latitude in radians
    return radians(this._lat)
  }

  get λ() {
    // Longitude in radians
    return radians(this._lon)
  }

  distanceFrom(dest) {
    let Δφ = radians(dest.lat - this.lat)
    let Δλ = radians(dest.lon - this.lon)

    let a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
      Math.cos(this.φ) * Math.cos(dest.φ) *
      Math.sin(Δλ/2) * Math.sin(Δλ/2);
    let c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c
  }

  bearingTo(dest) {
    let y = Math.sin(dest.λ - this.λ) * Math.cos(dest.φ)
    let x = Math.cos(this.φ) * Math.sin(dest.φ) -
      Math.sin(this.φ) * Math.cos(dest.φ) * Math.cos(dest.λ - this.λ)
    return degrees(Math.atan2(y, x));
  }

  distanceFromLine(start, end) {
    let δ13 = start.distanceFrom(this) / R;
    let θ13 = radians(start.bearingTo(this));
    let θ12 = radians(start.bearingTo(end));
    return Math.asin(Math.sin(δ13)*Math.sin(θ13-θ12)) * R;
  }

}

module.exports = {GeoCoord, degrees, radians}
