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
let statusCharacteristicUuid = CBUUID(string: "fc60")
let controlCharacteristicUuid = CBUUID(string: "fc61")

class BluetoothManager: NSObject {
    
    var _centralManager: CBCentralManager? = nil
    
    var scanningForPi = false
    
    var raspberryPis: Array<CBPeripheral> = []

    var _selectedPi: CBPeripheral? = nil
    var piConnected = false
    
    var _piRouteService: CBService? = nil

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
    
    func startScanning() {
        if let manager = _centralManager, manager.state != .poweredOn {
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
        
        if let manager = _centralManager {
            manager.connect(peripheral, options: nil)
        }
    }
    
    func disconnectPi() {
        if let pi = _selectedPi, let manager = _centralManager {
            pi.delegate = nil
            manager.cancelPeripheralConnection(pi)
        }
        _selectedPi = nil
        _piRouteService = nil
        characteristicsDiscovered = false
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
        }
        
        delegate?.peripheralFoundCallback(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let pi = _selectedPi, peripheral == pi {
            print("Info: Bluetooth: Pi connected")
            switch pi.state {
            case .connected: print("conn")
            case .connecting: print("conning")
            case .disconnected: print("disconn")
            default: print("disconning")
            }
            
            print("CONN (defo) AT \(NSDate().timeIntervalSince1970)")
            
            // Immediately (1 second later, because dodge) tries to discover the data writing service
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                print("Trying for services")
                switch pi.state {
                case .connected: print("conn")
                case .connecting: print("conning")
                case .disconnected: print("disconn")
                default: print("disconning")
                }
                pi.discoverServices([piServiceUuid])
            }
        } else {
            print("Warning: Bluetooth: An unknown peripheral connected!")
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("DISCONN AT \(NSDate().timeIntervalSince1970)")
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil {
            print("????")
            if let pi = _selectedPi, pi == peripheral {
                print("Info: Bluetooth: Route service found")
                
                for service in pi.services! {
                    if service.uuid == piServiceUuid {
                        _piRouteService = service
                        break
                    }
                }
                
                if let service = _piRouteService {
                    pi.discoverCharacteristics([routeCharacteristicUuid], for: service)
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
            if let piService = _piRouteService, service == piService {
                print("Info: Bluetooth: Characteristics discovered")
                print("Info: Bluetooth: Max packet length: \(peripheral.maximumWriteValueLength(for: .withResponse))")
                
                for characteristic in service.characteristics! {
                    switch characteristic.uuid {
                    case statusCharacteristicUuid:
                        peripheral.setNotifyValue(true, for: characteristic)
                        print("Info: Bluetooth: Set notify for the status characteristic")
                    default:
                        _ = 2
                    }
                }
                
                // The Data constructor (at least in this instance), combined with the pi at normal settings, produces a LITTLE ENDIAN
                // output from an int.
                // If we reverse it and then feed that to the Data constructor, it becomes BIG ENDIAN,
                // Or optionally use CFSwap<Whatever>HostToBig(arg:)
                //_selectedPi!.writeValue(Data(), for: _piRouteService!.characteristics![0], type: .withResponse)
                
                characteristicsDiscovered = true
                
                // TODO, actually pair lol
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
    func peripheralFoundCallback(_: CBPeripheral)
    func characteristicsFoundCallback(_: Array<CBCharacteristic>)
    func valueWrittenCallback(_: CBCharacteristic)
    func valueUpdatedCallback(_: CBCharacteristic)
}

extension BluetoothDelegate {
    func peripheralFoundCallback(_: CBPeripheral) {}
    func characteristicsFoundCallback(_: Array<CBCharacteristic>) {}
    func valueWrittenCallback(_: CBCharacteristic) {}
    func valueUpdatedCallback(_: CBCharacteristic) {}
}
