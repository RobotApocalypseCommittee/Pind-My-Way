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
    
    static func getRoutePollution(route: [CLLocationCoordinate2D]) -> [String : [String : Any]] {
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
                summary[pollutant] = ["available" : false, "average" : 0, "total":0]
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
}

// Makes it easier to do radians
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
