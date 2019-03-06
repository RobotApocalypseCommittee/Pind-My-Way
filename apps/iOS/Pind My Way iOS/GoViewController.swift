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

class GoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var routeJSON = JSON()
    var instructions : [NSAttributedString] = []
    var distances : [String] = []
    
    var pollutionDict : [String: [String : Any]] = [:]

    var currentLocation: CLLocationCoordinate2D? = nil
    
    var startScanningScheduledTimer: Timer? = nil
    
    @IBOutlet weak var pollutionStackView: UIStackView!
    
    @IBOutlet weak var startAdressLabel: UILabel!
    @IBOutlet weak var endAdressLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedBluetoothManager.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        if !sharedBluetoothManager.startScanning() {
            startScanningScheduledTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {_ in
                if sharedBluetoothManager.startScanning() {
                    self.startScanningScheduledTimer?.invalidate()
                }
            }
        }
        
        var n = 0
        for view in pollutionStackView.subviews {
            let label = view.subviews[0] as! UILabel
            
            let slider = view.subviews[1] as! UIProgressView

            if type(of: pollutionDict[pollutants[n]]!["average"]!) == String.self {
                label.text = pollutants[n] + " : N/A"
                slider.setProgress(1.0, animated: true)
                slider.progressTintColor = UIColor.lightGray
            }
            else {
                let average = pollutionDict[pollutants[n]]!["average"]! as! Float
                label.text = pollutants[n] + " : " + String(format: "%.2f", average/3*100) + "%"
                slider.setProgress(average/3, animated: true)
                
                if average/3 < 0.34 {
                    slider.progressTintColor = UIColor.green
                }
                else if average/3 < 0.66 {
                    slider.progressTintColor = UIColor.orange
                }
                else {
                    slider.progressTintColor = UIColor.red
                }
            }
            n += 1
        }
        
        startAdressLabel.text = String(describing: routeJSON["legs"][0]["start_address"])
        endAdressLabel.text = String(describing: routeJSON["legs"][0]["end_address"])
        distanceLabel.text = String(describing: routeJSON["legs"][0]["distance"]["text"])
        durationLabel.text = String(describing: routeJSON["legs"][0]["duration"]["text"])
        
        instructions.append(NSAttributedString(string: String(describing: routeJSON["legs"][0]["start_address"])))
        
        distances.append("0")
        
        for step in routeJSON["legs"][0]["steps"] {
            let data = String(describing: step.1["html_instructions"]).data(using: String.Encoding.unicode)!
            let attrStr = try? NSAttributedString(
                data: data,
                options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil)
            
            distances.append(String(describing: step.1["distance"]["text"]))
            instructions.append(attrStr!)
        }
        
        instructions.append(NSAttributedString(string: String(describing: routeJSON["legs"][0]["end_address"])))
        distances.append("0")
        
    }
    
    @objc func willEnterForeground() {
        if !sharedBluetoothManager.startScanning() {
            startScanningScheduledTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {_ in
                if sharedBluetoothManager.startScanning() {
                    self.startScanningScheduledTimer?.invalidate()
                }
            }
        }
    }
    
    @IBAction func sendButton_touchUpInside(_ sender: Any) {
        // If I want, add an activity indicator
        
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
        
        var routeCharacteristic: CBCharacteristic? = nil
        var controlCharacteristic: CBCharacteristic? = nil
        
        for characteristic in allCharacteristics {
            switch characteristic.uuid {
            case routeCharacteristicUuid:
                routeCharacteristic = characteristic
            case controlCharacteristicUuid:
                controlCharacteristic = characteristic
            default:
                _ = 2
            }
        }
        
        // Sends the route and control bit
        if let routeCharacteristic = routeCharacteristic {
            if sharedBluetoothManager.send(data: routeData, to: routeCharacteristic) {
                print("Route sent")
                
                if let controlCharacteristic = controlCharacteristic {
                    var num: UInt8 = 1
                    if sharedBluetoothManager.send(data: Data(bytes: &num, count: 1), to: controlCharacteristic) {
                        print("Control written")
                    } else {
                        print("Error in writing control")
                    }
                }
            } else {
                print("Some error sending route")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instructions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "instruction")! as! RouteInstructionCell
        if distances[indexPath.row] != "0" {
            cell.distanceLabel.text = distances[indexPath.row]
        }
        else {
            cell.distanceLabel.text = ""
        }
        
        let newFont = UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: UIFont.systemFontSize))
        let mattrStr = NSMutableAttributedString(attributedString: instructions[indexPath.row])
        mattrStr.beginEditing()
        mattrStr.enumerateAttribute(.font, in: NSRange(location: 0, length: mattrStr.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
            if let oFont = value as? UIFont, let newFontDescriptor = oFont.fontDescriptor.withFamily(newFont.familyName).withSymbolicTraits(oFont.fontDescriptor.symbolicTraits) {
                let nFont = UIFont(descriptor: newFontDescriptor, size: newFont.pointSize)
                mattrStr.removeAttribute(.font, range: range)
                mattrStr.addAttribute(.font, value: nFont, range: range)
            }
        }
        mattrStr.endEditing()
        
        cell.instructionLabel.attributedText = mattrStr
        
        return cell
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
        if peripheral.name == UserDefaults.standard.object(forKey: "pairedPiName") as? String {
            print("Trying to connect")
            sharedBluetoothManager.stopScanning()
            sharedBluetoothManager.connectPiAndService(peripheral: peripheral)
        }
    }
}

