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
    
    var bluetoothManager: BluetoothManager? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripheralTableView.delegate = self
        peripheralTableView.dataSource = self
        
        bluetoothManager = BluetoothManager() { () -> Void in
            self.peripheralTableView.reloadData()
        }
    }
    
    
    @IBAction func backButton_touchUpInside(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension BluetoothViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bluetoothManager!.raspberryPis.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothCell", for: indexPath) as! BluetoothTableCell
        
        cell.DeviceIDLabel.text = bluetoothManager!.raspberryPis[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bluetoothManager!.connectPiAndService(peripheral: bluetoothManager!.raspberryPis[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
