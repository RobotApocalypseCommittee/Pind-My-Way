//
//  AppDelegate.swift
//  Pind-My-Way-Map
//
//  Created by Atto Allas on 30/09/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

import SwiftyJSON
import GoogleMaps
import GooglePlaces

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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        GMSServices.provideAPIKey(apiKey)
        GMSPlacesClient.provideAPIKey(apiKey)
        
        print("MANUAL ROUTE: \(Utils.getRouteDataForBluetooth(route: routeJsonMAN).hexEncodedString())")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // Makes sure the pi is always manually disconnected
        sharedBluetoothManager.stopScanning()
        sharedBluetoothManager.disconnectPi()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        // Makes sure the pi is always manually disconnected
        sharedBluetoothManager.stopScanning()
        sharedBluetoothManager.disconnectPi()
    }


}

