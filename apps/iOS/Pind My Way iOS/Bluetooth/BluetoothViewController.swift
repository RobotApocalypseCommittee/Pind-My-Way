//
//  BluetoothViewController.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 08/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

class BluetoothViewController: UIViewController {
    
    @IBOutlet weak var peripheralTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var discoveredDevicesLabel: UILabel!
    
    var bluetoothManager: BluetoothManager?
    
    var chosenRow = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripheralTableView.delegate = self
        peripheralTableView.dataSource = self
        
        bluetoothManager = BluetoothManager() { () -> Void in
            self.peripheralTableView.reloadData()
        }
    }
    
    @IBAction func cancelButton_touchUpInside(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "introDone")
        performSegue(withIdentifier: "returnFromBluetooth", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toConnect" {
            let connectViewController = segue.destination as! ConnectBluetoothViewController
            
            connectViewController.peripheral = bluetoothManager!.raspberryPis[chosenRow]
            connectViewController.bluetoothManager = bluetoothManager
        }
    }
}

extension BluetoothViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if bluetoothManager!.raspberryPis.count > 0 {
            // This means a pi has been found, so no need to look like it's loading anymore
            activityIndicator.stopAnimating()
            peripheralTableView.isHidden = false
            discoveredDevicesLabel.isHidden = false
        }
        return bluetoothManager!.raspberryPis.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothCell", for: indexPath) as! BluetoothTableCell
        
        cell.DeviceIDLabel.text = bluetoothManager!.raspberryPis[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        chosenRow = indexPath.row
        
        performSegue(withIdentifier: "toConnect", sender: self)
    }
}
