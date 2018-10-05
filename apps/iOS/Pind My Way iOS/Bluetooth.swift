//
//  Bluetooth.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 03/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import Foundation
import CoreBluetooth

let piServiceUuid = CBUUID(string: "9540")
let writeCharacteristicUuid = CBUUID(string: "3bf0")

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager? = nil
    
    var raspberryPi: CBPeripheral? = nil
    var dataService: CBService? = nil
    var characteristicsDiscovered = false
    
    override init() {
        super.init()
        
        // Change queue to be more logical for bluetooth transfer
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Info: Bluetooth: Powered on")
            central.scanForPeripherals(withServices: [piServiceUuid], options: nil)
        default:
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Info: Bluetooth: Peripheral found")
        
        raspberryPi = peripheral
        raspberryPi!.delegate = self
        
        centralManager!.connect(peripheral, options: nil)
        
        centralManager!.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == raspberryPi! {
            print("Info: Bluetooth: Peripheral connected")
            raspberryPi!.discoverServices([piServiceUuid])
        } else {
            print("Warning: Bluetooth: An unknown peripheral connected!")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil {
            print("Info: Bluetooth: Service found")
            dataService = peripheral.services![0]
            raspberryPi!.discoverCharacteristics([writeCharacteristicUuid], for: dataService!)
        } else {
            print("Error: Bluetooth: \(error!)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error == nil {
            if service == dataService! {
                print("Info: Bluetooth: Characteristics discovered")
                
                var number = 0xbabe
                print("Info: Bluetooth: Max packet length: \(raspberryPi!.maximumWriteValueLength(for: .withResponse))")
                
                let data: Data = Data(Data(bytes: &number, count: 2).reversed())
                var allData: Data = Data()
                
                // Test to see if sending 500 bytes works - it does
                for _ in 1...8 {
                    allData.append(contentsOf: data)
                }
                
                
                // The Data constructor (at least in this instance), combined with the pi at normal settings, produces a LITTLE ENDIAN
                // output from an int.
                // If we reverse it and then feed that to the Data constructor, it becomes BIG ENDIAN,
                // Or optionally use CFSwap<Whatever>HostToBig(arg:)
                raspberryPi!.writeValue(allData, for: dataService!.characteristics![0], type: .withResponse)
                
                sleep(10)
                
                characteristicsDiscovered = true
            } else {
                print("Warning: Bluetooth: A service was discovered that was not the data service!")
            }
        } else {
            print("Error: Bluetooth: \(error!)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error: Bluetooth: \(error)")
        } else {
            print("Info: Bluetooth: Value written")
        }
    }
    
    /*
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print(error)
        print("Value read")
        
        characteristic.value!.withUnsafeBytes { characteristicBytes in
            print(Array(UnsafeBufferPointer(start: UnsafePointer<UInt16>(characteristicBytes), count: 8)).map { String(CFSwapInt16BigToHost($0), radix: 16) })
        }
    }
    */
}
