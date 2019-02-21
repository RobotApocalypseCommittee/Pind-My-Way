//
//  GoViewController.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 22/11/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit
import CoreBluetooth
import SwiftyJSON
import CoreLocation

class GoViewController: UIViewController {
    
    var routeJSON = JSON()
    
    var bluetoothManager: BluetoothManager? = nil
    var currentLocation: CLLocationCoordinate2D? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        
        bluetoothManager = BluetoothManager()
        
        bluetoothManager?.delegate = self
    }
    
    @IBAction func sendButton_touchUpInside(_ sender: Any) {
        guard let bluetoothManager = bluetoothManager else {
            print("No BT Manager!")
            return
        }
        
        // Add current location TODO
        let routeData: Data
        if let startLocation = currentLocation {
            routeData = Utils.getRouteDataForBluetooth(route: routeJSON, withStart: startLocation)
        } else {
            routeData = Utils.getRouteDataForBluetooth(route: routeJSON)
        }
        
        if !bluetoothManager.characteristicsDiscovered {
            print("Characteristics not discovered!")
            return
        }
        
        let allCharacteristics = bluetoothManager._selectedPi!.services![0].characteristics!
        for characteristic in allCharacteristics {
            switch characteristic.uuid {
            case routeCharacteristicUuid:
                if bluetoothManager.send(data: routeData, to: characteristic) {
                    print("Route sent")
                } else {
                    print("Some error sending route")
                }
            case controlCharacteristicUuid:
                var num: UInt8 = 1
                if bluetoothManager.send(data: Data(bytes: &num, count: 1), to: characteristic) {
                    print("Control written")
                } else {
                    print("Error in writing control")
                }
            default:
                _ = 2
            }
        }
    }
    
    @IBAction func backButton_touchUpInside(_ sender: Any) {
        performSegue(withIdentifier: "returnFromGo", sender: self)
    }
}

extension GoViewController: BluetoothDelegate {
    func valueWrittenCallback(_: CBCharacteristic) {
        print("Value Written from GO VIEW CONTROLLER")
    }
    
    func peripheralFoundCallback(_ peripheral: CBPeripheral) {
        print("Periph found: \(peripheral.name ?? "Unknown")")
        
        if peripheral.name == UserDefaults.standard.object(forKey: "pairedPiName") as? String || true {
            print("Trying to connect")
            bluetoothManager!.connectPiAndService(peripheral: peripheral)
        }
    }
    
    func characteristicsFoundCallback(_: Array<CBCharacteristic>) {
        print("Characteristics found")
    }
}
