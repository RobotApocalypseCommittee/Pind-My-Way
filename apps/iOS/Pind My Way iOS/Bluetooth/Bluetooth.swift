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
let routeCharacteristicUuid = CBUUID(string: "3bf0")
let uniqueIDCharacteristicUuid = CBUUID(string: "fc58")
let settableNameCharacteristicUuid = CBUUID(string: "fc59")

class BluetoothManager: NSObject {
    
    var _centralManager: CBCentralManager? = nil
    
    var scanningForPi = false
    
    var raspberryPis: Array<CBPeripheral> = []

    var _selectedPi: CBPeripheral? = nil
    var piConnected = false
    
    var _piRouteService: CBService? = nil

    var characteristicsDiscovered = false
    
    let peripheralFoundCallback: () -> Void
    
    var peripheralPairedCallback: (() -> Void)?
    
    init(withCallback callback: @escaping () -> Void) {
        peripheralFoundCallback = callback
        peripheralPairedCallback = nil
        
        super.init()
        
        // Change queue to be more logical for bluetooth transfer
        _centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        if _centralManager!.state != .poweredOn {
            print("Warning: Bluetooth: Cannot start scanning before being turned on!")
            return
        }
        if !scanningForPi {
            _centralManager!.scanForPeripherals(withServices: [piServiceUuid], options: nil)
            scanningForPi = true
        }
    }
    
    func stopScanning() {
        if scanningForPi {
            _centralManager!.stopScan()
            scanningForPi = false
        }
    }
    
    func connectPiAndService(peripheral: CBPeripheral) {
        _piRouteService = nil
        characteristicsDiscovered = false
        
        peripheral.delegate = self
        _selectedPi = peripheral
        
        _centralManager!.connect(_selectedPi!, options: nil)
    }
    
    func disconnectPi() {
        if let _selectedPi = _selectedPi {
            _selectedPi.delegate = nil
            _centralManager!.cancelPeripheralConnection(_selectedPi)
        }
        _selectedPi = nil
        _piRouteService = nil
        characteristicsDiscovered = false
    }
    
    deinit {
        disconnectPi()
        stopScanning()
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Info: Bluetooth: Powered on")
            scanningForPi = true
            central.scanForPeripherals(withServices: [piServiceUuid], options: nil)
        default:
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Info: Bluetooth: Peripheral found")
        
        if !raspberryPis.contains(peripheral) {
            raspberryPis.insert(peripheral, at: raspberryPis.endIndex)
            
            peripheralFoundCallback()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == _selectedPi! {
            print("Info: Bluetooth: Pi connected")
            
            // Immediately tries to discover the data writing service
            _selectedPi!.discoverServices([piServiceUuid])
        } else {
            print("Warning: Bluetooth: An unknown peripheral connected!")
        }
    }
    
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil {
            print("Info: Bluetooth: Route service found")
            _piRouteService = peripheral.services![0]
            _selectedPi!.discoverCharacteristics([routeCharacteristicUuid], for: _piRouteService!)
        } else {
            print("Error: Bluetooth: \(error!)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error == nil {
            if service == _piRouteService! {
                print("Info: Bluetooth: Characteristics discovered")
                print("Info: Bluetooth: Max packet length: \(_selectedPi!.maximumWriteValueLength(for: .withResponse))")
                
                // The Data constructor (at least in this instance), combined with the pi at normal settings, produces a LITTLE ENDIAN
                // output from an int.
                // If we reverse it and then feed that to the Data constructor, it becomes BIG ENDIAN,
                // Or optionally use CFSwap<Whatever>HostToBig(arg:)
                //_selectedPi!.writeValue(Data(), for: _piRouteService!.characteristics![0], type: .withResponse)
                
                characteristicsDiscovered = true
                
                // TODO, actually pair lol
                if peripheralPairedCallback != nil {
                    peripheralPairedCallback!()
                }
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
