//
//  DirectionManager.swift
//  Pind-My-Way-Map
//
//  Created by Atto Allas on 30/09/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import Foundation
import GoogleMaps
import SwiftyJSON
import SwiftyXML

let baseURLComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/directions/json")!

class Utils {
    
    // In meters
    static let earthRadius = 6371000.0
    
    // This function should be called asynchronously
    static func getDirections(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping (JSON?)->()) {
        var urlComponents = baseURLComponents
        
        urlComponents.queryItems = [
            URLQueryItem(name: "origin", value: "\(start.latitude),\(start.longitude)"),
            URLQueryItem(name: "destination", value: "\(end.latitude),\(end.longitude)"),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "mode", value: "bicycling"),
            URLQueryItem(name: "alternatives", value: "true"),
            URLQueryItem(name: "units", value: "metric")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            guard let _:NSData = data as NSData?, let _:URLResponse = response, error == nil else {
                print("Error: Directions: \(error!)")
                return
            }
            do {
                let directionsJson = try JSON.init(data: data!)
                completion(directionsJson)
            } catch let error {
                print("Error: Directions: \(error.localizedDescription))")
            }
        }
        
        task.resume()
    }
    
    static func getDistance(between coord1: CLLocationCoordinate2D, and coord2: CLLocationCoordinate2D) -> Double {
        let lat1 = coord1.latitude.degreesToRadians
        let lat2 = coord2.latitude.degreesToRadians
        
        let deltaLat = (coord2.latitude-coord1.latitude).degreesToRadians
        let deltaLon = (coord2.longitude-coord1.longitude).degreesToRadians
        
        let a = sin(deltaLat/2.0) * sin(deltaLat/2.0) + cos(lat1) * cos(lat2) * sin(deltaLon/2.0) * sin(deltaLon/2.0)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    static func getBearing(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let lat1 = coord1.latitude.degreesToRadians
        let lat2 = coord2.latitude.degreesToRadians
        
        let deltaLon = (coord2.longitude-coord1.longitude).degreesToRadians
        
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        // The + 360 mod 360 is because atan2 returns -180 to 180, and this should really be 0 to 360
        // Remainder is literally just mod for floating point
        let bear = atan2(y, x).radiansToDegrees + 360
        return bear < 360 ? bear : bear - 360
    }
    
    static func getRoutePollution(route: [CLLocationCoordinate2D]) -> [String : [String : Any]] {
        return [:]
        
        //Thins out the route, only using points every ~100m
        var thinRoute : [CLLocationCoordinate2D] = []
        for i in stride(from: 0, to: route.count, by: 10) {
            thinRoute.append(route[i])
        }
        
        //Creates an array of all the monitoring stations
        var dataPoints : [JSON] = []
        
        let localAuthority = pollutionResp["DailyAirQualityIndex"]["LocalAuthority"]
        
        guard !localAuthority.isEmpty else {
            return [:]
        }
        
        for area in localAuthority {
            if area.1["Site"].exists() {
                for site in area.1["Site"] {
                    dataPoints.append(site.1)
                }
            }
        }
        
        var closestReadings : [JSON] = []
        
        //Gets the closest monitoring point to every route point
        for coord in thinRoute {
            var closestAreaIndex = 0;
            var closestAreaDistance : Float = 9999.0;
            var i = 0
            for area in dataPoints {
                //Calculates distance from route point to pollution monitoring point
                let areaLat = area["@Latitude"].floatValue
                let areaLong = area["@Longitude"].floatValue
                let distance = Float(pow(abs(Double(areaLat) - coord.latitude), 2) + pow(abs(Double(areaLong) - coord.longitude), 2)).squareRoot()

                if distance < closestAreaDistance {
                    closestAreaIndex = i
                    closestAreaDistance = distance;
                }
                i += 1
            }
            closestReadings.append(dataPoints[closestAreaIndex]["Species"])
        }

        //Stores all the pollution values for every point on the route
        var allPollutionReadings : [String:[Float]] = ["O3":[], "PM10":[], "NO2":[], "SO2":[], "PM25":[]]
        for readings in closestReadings {
            for reading in readings {
                if allPollutionReadings[reading.1["@SpeciesCode"].stringValue] != nil {
                    allPollutionReadings[reading.1["@SpeciesCode"].stringValue]!.append(Float(reading.1["@AirQualityIndex"].intValue))
                }
            }
        }
        
        //Summarises, getting average and total for every pollutants
        var summary : [String : [String:Any]] = [:]
        for (pollutant, values) in allPollutionReadings {
            if values == [] {
                summary[pollutant] = ["available" : false, "average" : "N/A", "total" : "N/A"]
            }
            else {
                let total = values.reduce(0, +)
                let average = total/Float(values.count)
                summary[pollutant] = ["available" : true, "average" : average, "total" : total]
            }
        }
        
        print(summary)
        return summary
    }
    
    static func getRouteDataForBluetooth(route: JSON, withStart start: CLLocationCoordinate2D) -> Data {
        var allStepsData = Data()
        
        var firstStartPoint = true
        
        for leg in route["legs"].array! {
            for step in leg["steps"].array! {
                
                let startStep: CLLocationCoordinate2D
                
                // This is to allow the first "start point" from which the bearing is calculated to be specified by the caller
                // This exists so a more accurate first bearing can be calculated relative to the user's starting position, as opposed to the first point on the Google Maps polyline
                if firstStartPoint {
                    startStep = start
                    firstStartPoint = false
                } else {
                    startStep = CLLocationCoordinate2D(latitude: step["start_location"]["lat"].double!, longitude: step["start_location"]["lng"].double!)
                }
                
                let endStep = CLLocationCoordinate2D(latitude: step["end_location"]["lat"].double!, longitude: step["end_location"]["lng"].double!)
                
                let bearing = Int(round(getBearing(from: startStep, to: endStep)))
                var bearingOverTwo = UInt8(bearing / 2)
                
                let bearingData = Data(bytes: &bearingOverTwo, count: 1)
                
                var maneuver = UInt8(0)
                if let stringManeuver = step["maneuver"].string {
                    switch stringManeuver {
                    case "turn-slight-right": maneuver = 1
                    case "turn-right": maneuver = 2
                    case "turn-sharp-right": maneuver = 3
                    case "uturn-right": maneuver = 4
                    case "uturn-left": maneuver = 5
                    case "turn-sharp-left": maneuver = 6
                    case "turn-left": maneuver = 7
                    case "turn-slight-left": maneuver = 8
                    case "straight": maneuver = 0
                    case "ramp-right": maneuver = 17
                    case "ramp-left": maneuver = 18
                    case "roundabout-right": maneuver = 33
                    case "roundabout-left": maneuver = 34
                    default: maneuver = 255
                    }
                }
                
                let maneuverData = Data(bytes: &maneuver, count: 1)
                
                var endStepLatitude = Double(endStep.latitude)
                var endStepLongitude = Double(endStep.longitude)
                
                let endStepLatitudeData = Data(bytes: &endStepLatitude, count: 8)
                let endStepLongitudeData = Data(bytes: &endStepLongitude, count: 8)
                
                allStepsData.append(bearingData)
                allStepsData.append(maneuverData)
                allStepsData.append(endStepLatitudeData)
                allStepsData.append(endStepLongitudeData)
            }
        }
        
        return allStepsData
    }
    
    static func getRouteDataForBluetooth(route: JSON) -> Data {
        let firstStep = route["legs"][0]["steps"][0]
        
        return getRouteDataForBluetooth(route: route, withStart: CLLocationCoordinate2D(latitude: firstStep["start_location"]["lat"].double!, longitude: firstStep["start_location"]["lng"].double!))
    }
}

// Makes it easier to do radians
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
