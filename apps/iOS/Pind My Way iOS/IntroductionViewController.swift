//
//  IntroductionViewController.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 09/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

class IntroductionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueButton_touchUpInside(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "introDone")
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
