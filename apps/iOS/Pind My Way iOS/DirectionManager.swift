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

class DirectionManager {
    
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
                print("error in request")
                return
            }
            do {
                let directionsJson = try JSON.init(data: data!)
                completion(directionsJson)
            } catch {
                print("Error with JSON")
            }
        }
        
        task.resume()
    }
}
