//
//  Bluetooth.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 03/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import Foundation
import CoreBluetooth

let piServiceUuid = CBUUID(string: "ed00")
let versionCharacteristicUuid = CBUUID(string: "ed01")
let routeCharacteristicUuid = CBUUID(string: "ed02")
let uniqueIDCharacteristicUuid = CBUUID(string: "ed03")
let settableNameCharacteristicUuid = CBUUID(string: "ed04")
let statusCharacteristicUuid = CBUUID(string: "ed05")
let controlCharacteristicUuid = CBUUID(string: "ed06")

let allCharacteristicsUuids = [versionCharacteristicUuid, routeCharacteristicUuid, uniqueIDCharacteristicUuid, settableNameCharacteristicUuid, statusCharacteristicUuid, controlCharacteristicUuid]

class BluetoothManager: NSObject {
    
    var _centralManager: CBCentralManager? = nil
    
    var scanningForPi = false
    
    var raspberryPis: Array<CBPeripheral> = []

    var _selectedPi: CBPeripheral? = nil
    var piConnected = false
    
    var _piService: CBService? = nil

    var characteristicsDiscovered = false
    
    /*
    let peripheralFoundCallback: () -> Void
    
    var peripheralPairedCallback: (() -> Void)?
    
    var valueWrittenCallback: ((CBCharacteristic) -> Void)? = nil
    var valueUpdatedCallback: ((CBCharacteristic) -> Void)? = nil
    */
    
    weak var delegate: BluetoothDelegate?
    
    override init() {
        super.init()
        
        // Change queue to be more logical for bluetooth transfer
        _centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() -> Bool {
        // Returns true for success, false for failure
        if let manager = _centralManager {
            if manager.state != .poweredOn {
                print("Warning: Bluetooth: Cannot start scanning before being turned on!")
                return false
            } else if !scanningForPi {
                manager.scanForPeripherals(withServices: [piServiceUuid], options: nil)
                scanningForPi = true
            }
            
            return true
        }
        
        return false
    }
    
    func stopScanning() {
        if scanningForPi {
            _centralManager?.stopScan()
            scanningForPi = false
        }
    }
    
    func connectPiAndService(peripheral: CBPeripheral) {
        _piService = nil
        characteristicsDiscovered = false
        
        peripheral.delegate = self
        _selectedPi = peripheral
        
        if let manager = _centralManager {
            manager.cancelPeripheralConnection(peripheral) // To make sure there is nothing pending
            manager.connect(peripheral, options: nil)
        }
    }
    
    func disconnectPi(noSend legacy: Bool) {
        if let pi = _selectedPi, let manager = _centralManager {
            if !legacy {
                if let services = pi.services, services.count > 0, let characteristics = services[0].characteristics {
                    for characteristic in characteristics {
                        switch characteristic.uuid {
                        case controlCharacteristicUuid:
                            var disconnectControl: UInt8 = 3
                            _ = send(data: Data(bytes: &disconnectControl, count: 1), to: characteristic)
                        default:
                            _ = 2
                        }
                    }
                }
            } else {
                pi.delegate = nil
                manager.cancelPeripheralConnection(pi)
            }
        }
        
        _selectedPi = nil
        _piService = nil
        characteristicsDiscovered = false
    }
    
    func disconnectPi() {
        disconnectPi(noSend: false)
    }
    
    func send(data: Data, to characteristic: CBCharacteristic) -> Bool {
        // returns true if succeeded, otherwise false
        if characteristicsDiscovered {
            if let pi = _selectedPi {
                pi.writeValue(data, for: characteristic, type: .withResponse)
                return true
            }
        }
        return false
    }
    
    func updateValue(for characteristic: CBCharacteristic) -> Bool {
        // returns true if succeeded, otherwise false
        if characteristicsDiscovered {
            if let pi = _selectedPi {
                pi.readValue(for: characteristic)
                return true
            }
        }
        return false
    }
    
    deinit {
        print("Bluetooth Manager Deinited")
        disconnectPi()
        stopScanning()
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Info: Bluetooth: Powered on")
        default:
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if !raspberryPis.contains(peripheral) {
            raspberryPis.insert(peripheral, at: raspberryPis.endIndex)
        }
        
        delegate?.peripheralFoundCallback(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let pi = _selectedPi, peripheral == pi {
            print("Info: Bluetooth: Pi connected at \(NSDate().timeIntervalSince1970)")
            
            // Needed because of CoreBluetooth caching
            if peripheral.services != nil {
                self.peripheral(peripheral, didDiscoverServices: nil)
            } else {
                // Immediately tries to discover the data writing service
                pi.discoverServices([piServiceUuid])
            }
        } else {
            print("Warning: Bluetooth: An unknown peripheral connected!")
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Info: Bluetooth: DISCONN AT \(NSDate().timeIntervalSince1970)")
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil {
            if let pi = _selectedPi, pi == peripheral {
                print("Info: Bluetooth: Route service found")
                
                for service in pi.services! {
                    if service.uuid == piServiceUuid {
                        _piService = service
                        break
                    }
                }
                
                if let service = _piService {
                    // Needed because of CoreBluetooth caching
                    if service.characteristics != nil {
                        self.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: nil)
                    } else {
                        pi.discoverCharacteristics(allCharacteristicsUuids, for: service)
                    }
                }
            } else {
                print("Error: Bluetooth: Services were discovered for something that wasn't the pi!")
            }
        } else {
            print("Error: Bluetooth: \(error!)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error == nil {
            if let piService = _piService, service == piService {
                print("Info: Bluetooth: Max packet length: \(peripheral.maximumWriteValueLength(for: .withResponse))")
                
                for characteristic in service.characteristics! {
                    switch characteristic.uuid {
                    case statusCharacteristicUuid:
                        peripheral.setNotifyValue(true, for: characteristic)
                        print("Info: Bluetooth: Set notify for the status characteristic")
                    case versionCharacteristicUuid:
                        print("Hello")
                        peripheral.readValue(for: characteristic)
                    default:
                        _ = 2
                    }
                }
                
                characteristicsDiscovered = true
                
                delegate?.characteristicsFoundCallback(service.characteristics!)
            } else {
                print("Warning: Bluetooth: A service was discovered that was not the pi service!")
            }
        } else {
            print("Error: Bluetooth: \(error!)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Bluetooth: Error: Write Value: \(error)")
        }
        
        delegate?.valueWrittenCallback(characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Bluetooth: Error: Update Value: \(error)")
        }
        
        delegate?.valueUpdatedCallback(characteristic)
    }
    
}

protocol BluetoothDelegate: AnyObject {
    func peripheralFoundCallback(_ peripheral: CBPeripheral)
    func characteristicsFoundCallback(_ characteristics: Array<CBCharacteristic>)
    func valueWrittenCallback(_ characteristic: CBCharacteristic)
    func valueUpdatedCallback(_ characteristic: CBCharacteristic)
}

extension BluetoothDelegate {
    func defaultPeripheralFoundCallback(_ peripheral: CBPeripheral) {
        print("Info: Bluetooth: Peripheral found with name \"\(peripheral.name ?? "nil")\"")
    }
    func defaultCharacteristicsFoundCallback(_ characteristics: Array<CBCharacteristic>) {
        print("Info: Bluetooth: Characteristics were found")
    }
    func defaultValueWrittenCallback(_ characteristic: CBCharacteristic) {
        print("Info: Bluetooth: Value written to a characteristic with UUID \"\(characteristic.uuid)\"")
    }
    func defaultValueUpdatedCallback(_ characteristic: CBCharacteristic) {
        // Technically the ?? "nil" is never used, but otherwise Xcode complains
        print("Info: Bluetooth: Characteristic with UUID \"\(characteristic.uuid)\" has a value of \"\(characteristic.value?.hexEncodedString() ?? "nil")\"")
    }
    
    
    func peripheralFoundCallback(_ peripheral: CBPeripheral) {
        defaultPeripheralFoundCallback(peripheral)
    }
    func characteristicsFoundCallback(_ characteristics: Array<CBCharacteristic>) {
        defaultCharacteristicsFoundCallback(characteristics)
    }
    func valueWrittenCallback(_ characteristic: CBCharacteristic) {
        defaultValueWrittenCallback(characteristic)
    }
    func valueUpdatedCallback(_ characteristic: CBCharacteristic) {
        defaultValueUpdatedCallback(characteristic)
    }
}
