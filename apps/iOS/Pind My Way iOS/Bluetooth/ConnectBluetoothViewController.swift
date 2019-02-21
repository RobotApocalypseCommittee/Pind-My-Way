//
//  ConnectBluetoothViewController.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 20/11/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConnectBluetoothViewController: UIViewController {
    
    var peripheral: CBPeripheral?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var pairLabel: UILabel!
    @IBOutlet weak var completeImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pairLabel.text = "Pairing to\n\(peripheral?.name ?? "your Pi-nd My Way Hub")"
        
        sharedBluetoothManager.connectPiAndService(peripheral: peripheral!)
    }

    @IBAction func cancelButton_touchUpInside(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "introDone")
        
        sharedBluetoothManager.disconnectPi()
        
        performSegue(withIdentifier: "returnFromConnect", sender: self)
    }
}

extension ConnectBluetoothViewController: BluetoothDelegate {
    func characteristicsFoundCallback(_ characteristics: Array<CBCharacteristic>) {
        // TODO make unique
        UserDefaults.standard.set(sharedBluetoothManager._selectedPi?.name, forKey: "pairedPiName")
        
        // Stop being the delegate and disconnect the pi
        sharedBluetoothManager.delegate = nil
        sharedBluetoothManager.disconnectPi()
        
        // TODO, actually pair lol
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.completeImage.frame = CGRect(x: self.view.center.x-5, y: self.view.center.y-5, width: 10, height: 10)
            self.completeImage.isHidden = false
            
            // Change to Unique ID
            
            
            // Numbers that look nice
            UIView.animate(withDuration: 0.5) {
                self.completeImage.transform = CGAffineTransform(scaleX: 5, y: 5)
            }
            
            // This number is the # of seconds for which it'll wait before auto-exiting
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) {_ in
                UserDefaults.standard.set(true, forKey: "introDone")
                
                self.performSegue(withIdentifier: "returnFromConnect", sender: self)
            }
        }
    }
}
