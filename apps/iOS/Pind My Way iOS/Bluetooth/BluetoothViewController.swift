//
//  BluetoothViewController.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 08/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit
import CoreBluetooth

class BluetoothViewController: UIViewController {
    
    @IBOutlet weak var peripheralTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var discoveredDevicesLabel: UILabel!
    
    var startScanningScheduledTimer: Timer? = nil
    
    var chosenRow = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripheralTableView.delegate = self
        peripheralTableView.dataSource = self
        
        sharedBluetoothManager.delegate = self
        if !sharedBluetoothManager.startScanning() {
            startScanningScheduledTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {_ in
                if sharedBluetoothManager.startScanning() {
                    self.startScanningScheduledTimer?.invalidate()
                }
            }
        }
    }
    
    @IBAction func cancelButton_touchUpInside(_ sender: Any) {
        sharedBluetoothManager.stopScanning()
        sharedBluetoothManager.disconnectPi()
        
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "introDone")
        performSegue(withIdentifier: "returnFromBluetooth", sender: self)
        #else
        // Just leave please
        UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            exit(0)
        }
        #endif
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toConnect" {
            let connectViewController = segue.destination as! ConnectBluetoothViewController
            
            connectViewController.peripheral = sharedBluetoothManager.raspberryPis[chosenRow]
            sharedBluetoothManager.delegate = connectViewController
        }
    }
}

extension BluetoothViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sharedBluetoothManager.raspberryPis.count > 0 {
            // This means a pi has been found, so no need to look like it's loading anymore
            activityIndicator.stopAnimating()
            peripheralTableView.isHidden = false
            discoveredDevicesLabel.isHidden = false
        }
        return sharedBluetoothManager.raspberryPis.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothCell", for: indexPath) as! BluetoothTableCell
        
        cell.DeviceIDLabel.text = sharedBluetoothManager.raspberryPis[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        chosenRow = indexPath.row
        
        sharedBluetoothManager.stopScanning()
        
        performSegue(withIdentifier: "toConnect", sender: self)
    }
}

extension BluetoothViewController: BluetoothDelegate {
    func peripheralFoundCallback(_ peripheral: CBPeripheral) {
         defaultPeripheralFoundCallback(peripheral)
        
        self.peripheralTableView.reloadData()
    }
}
