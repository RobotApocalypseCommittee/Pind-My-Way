//
//  Singleton.swift
//  Pind-My-Way-Map
//
//  Created by Atto Allas on 30/09/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import Foundation
import SwiftyJSON

#warning("Enter the real Google Maps API Key")
let apiKey = ""

let sharedBluetoothManager = BluetoothManager()

var pollutionResp : JSON = []
var localAuthorities : [JSON] = []
let pollutants = ["PM10", "PM25", "NO2", "SO2", "O3"]

let routeJsonString = """
{
"legs":[
{
"steps":[
{
"start_location":{
"lat":51.489003,
"lng":-0.160582
},
"end_location":{
"lat":51.489721,
"lng":-0.159423
},
"maneuver":"straight"
},
{
"start_location":{
"lat":51.489721,
"lng":-0.159423
},
"end_location":{
"lat":51.488579,
"lng":-0.157443
},
"maneuver":"turn-right"
},
{
"start_location":{
"lat":51.488579,
"lng":-0.157443
},
"end_location":{
"lat":51.486959,
"lng":-0.160022
},
"maneuver":"turn-right"
},
{
"start_location":{
"lat":51.486959,
"lng":-0.160022
},
"end_location":{
"lat":51.488066,
"lng":-0.161982
},
"maneuver":"turn-right"
},
{
"start_location":{
"lat":51.488066,
"lng":-0.161982
},
"end_location":{
"lat":51.488828,
"lng":-0.160859
},
"maneuver":"turn-right"
}
]
}
]
}
"""
let routeJsonMAN = JSON(parseJSON: routeJsonString)

let pollutionMaximum : Float = 5.0;
