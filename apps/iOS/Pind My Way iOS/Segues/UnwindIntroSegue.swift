//
//  UnwindIntroSegue.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 20/11/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

class UnwindIntroSegue: UIStoryboardSegue {
    override func perform() {
        let secondViewControllerView = self.source.view!
        let firstViewControllerView = self.destination.view!
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let window = UIApplication.shared.keyWindow
        
        firstViewControllerView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        window?.insertSubview(firstViewControllerView, belowSubview: secondViewControllerView)
        
        // Who knows why this is needed...
        window?.sendSubviewToBack(firstViewControllerView)
        
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
    
            secondViewControllerView.frame = (secondViewControllerView.frame.offsetBy(dx: 0, dy: screenHeight))
            
        }, completion: { _ in
            self.destination.dismiss(animated: false, completion: nil)
        })
    }
}
