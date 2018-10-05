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
    
    static func getPollution(location: CLLocationCoordinate2D) {
        
        //return

        let url = URL(string: "https://api.openweathermap.org/pollution/v1/co/\(location.latitude),\(location.longitude)/current.json?appid=\(pollutionApiKey)")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if let data = data {
                do {
                    let json = try JSON(data: data)
                    print(json)
                    // Multiply by molar weight of air and of CO and by 1000000 because why not they're all magic numbers anyway tbh - i think this is right, it seems rightish so i mean
                    if let mixingRatioReading = json["data"][0]["value"].float {
                        let groundReading : Float = mixingRatioReading * 1000000 * 28.97 * 28.01
                        print("Info: Pollution: CO = \(groundReading)")
                    } else {
                        print("Warning: Pollution data incorrect")
                    }
                    
                }  catch let error {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        task.resume()
        
    }
}

// Makes it easier to do radians
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
