//
//  Bluetooth.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 03/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager? = nil
    
    var raspberryPi: CBPeripheral? = nil
    var dataService: CBService? = nil
    
    override init() {
        super.init()
        
        // Change queue to be more logical for bluetooth transfer
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Powered on")
            central.scanForPeripherals(withServices: [CBUUID(string: "123a")], options: nil)
        default:
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        raspberryPi = peripheral
        raspberryPi!.delegate = self
        
        centralManager!.connect(peripheral, options: nil)
        
        centralManager!.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == raspberryPi! {
            raspberryPi!.discoverServices([CBUUID(string: "123a")])
        } else {
            print("An unknown peripheral connected!")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil {
            dataService = peripheral.services![0]
            raspberryPi!.discoverCharacteristics([CBUUID(string: "1135")], for: dataService!)
        } else {
            print(error!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error == nil {
            if service == dataService! {
                var number = 66
                raspberryPi!.writeValue(Data(bytes: &number, count: 1), for: dataService!.characteristics![0], type: .withResponse)
            } else {
                print("A service was discovered that was not the data service!")
            }
        } else {
            print(error!)
        }
    }
}
