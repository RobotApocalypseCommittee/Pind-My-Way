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

    var currentLocation: CLLocationCoordinate2D? = nil
    
    var startScanningScheduledTimer: Timer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedBluetoothManager.delegate = self
        
        if !sharedBluetoothManager.startScanning() {
            startScanningScheduledTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {_ in
                if sharedBluetoothManager.startScanning() {
                    self.startScanningScheduledTimer?.invalidate()
                }
            }
        }
    }
    
    @IBAction func sendButton_touchUpInside(_ sender: Any) {
        // Add current location TODO
        let routeData: Data
        if let startLocation = currentLocation {
            routeData = Utils.getRouteDataForBluetooth(route: routeJSON, withStart: startLocation)
        } else {
            routeData = Utils.getRouteDataForBluetooth(route: routeJSON)
        }
        
        if !sharedBluetoothManager.characteristicsDiscovered {
            print("Characteristics not discovered!")
            return
        }
        
        let allCharacteristics = sharedBluetoothManager._selectedPi!.services![0].characteristics!
        for characteristic in allCharacteristics {
            switch characteristic.uuid {
            case routeCharacteristicUuid:
                if sharedBluetoothManager.send(data: routeData, to: characteristic) {
                    print("Route sent")
                } else {
                    print("Some error sending route")
                }
            case controlCharacteristicUuid:
                var num: UInt8 = 1
                if sharedBluetoothManager.send(data: Data(bytes: &num, count: 1), to: characteristic) {
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
        sharedBluetoothManager.stopScanning()
        sharedBluetoothManager.disconnectPi()
        
        performSegue(withIdentifier: "returnFromGo", sender: self)
    }
}

extension GoViewController: BluetoothDelegate {
    func valueWrittenCallback(_ characteristic: CBCharacteristic) {
        defaultValueWrittenCallback(characteristic)
        print("Info: Bluetooth: This value was written from GoViewController")
    }
    
    func peripheralFoundCallback(_ peripheral: CBPeripheral) {
        defaultPeripheralFoundCallback(peripheral)
        
        // TODO fix
        if peripheral.name == UserDefaults.standard.object(forKey: "pairedPiName") as? String || true {
            print("Trying to connect")
            sharedBluetoothManager.stopScanning()
            sharedBluetoothManager.connectPiAndService(peripheral: peripheral)
        }
    }
}
