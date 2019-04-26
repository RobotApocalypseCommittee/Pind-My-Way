//
//  LatestJourneyViewController.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 24/04/2019.
//  Copyright © 2019 Atto Allas. All rights reserved.
//

import UIKit

class LatestJourneyViewController: UIViewController {
    
    var distance: UInt32? = nil // meters
    var time: UInt32? = nil // seconds
    var speed: Double? = nil // m/s

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let distance = self.distance {
            distanceLabel.text = "Distance: \(distance) meters (\(Double(distance)/109.728) football fields)"
        }
        
        if let time = self.time {
            timeLabel.text = "Time taken: \(floor(Double(time)/60)) minutes, \(time % 60) seconds (\(Double(time)/3600/24/365.25/80*100)% of an average human lifespan)"
        }
        
        if let speed = self.speed {
            speedLabel.text = "Average speed: \(speed/1000*3600) km/h (\(speed/3960*100)% of the speed of sound in hardwood)"
        }

        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueButton_touchUpInside(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
