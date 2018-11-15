//
//  IntroductionViewController.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 09/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

class IntroductionViewController: UIViewController {
    
    let toBluetoothTransition = HorizontalAnimator(goingForwards: true)
    let fromBluetoothTransition = HorizontalAnimator(goingForwards: false)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueButton_touchUpInside(_ sender: Any) {
        /*UserDefaults.standard.set(true, forKey: "introDone")
        self.dismiss(animated: true, completion: nil)*/
        
        let newViewController = UIStoryboard(name: "Introduction", bundle: nil).instantiateViewController(withIdentifier: "Bluetooth")
        newViewController.transitioningDelegate = self
        self.present(newViewController, animated: true, completion: nil)
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

extension IntroductionViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return toBluetoothTransition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return fromBluetoothTransition
    }
}
