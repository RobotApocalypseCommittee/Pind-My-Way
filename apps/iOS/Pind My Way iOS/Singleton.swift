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
