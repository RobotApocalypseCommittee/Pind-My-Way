//
//  HorizontalSegue.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 20/11/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

class HorizontalSegue: UIStoryboardSegue {
    override func perform() {
        let firstViewControllerView = self.source.view!
        let secondViewControllerView = self.destination.view!
    
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let window = UIApplication.shared.keyWindow
        
        secondViewControllerView.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: screenHeight)
        window?.insertSubview(secondViewControllerView, aboveSubview: firstViewControllerView)
        
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            
            firstViewControllerView.frame = (firstViewControllerView.frame.offsetBy(dx: -screenWidth, dy: 0))
            secondViewControllerView.frame = (secondViewControllerView.frame.offsetBy(dx: -screenWidth, dy: 0))
            
        }, completion: { _ in
            self.source.present(self.destination, animated: false, completion: nil)
        })
    }
}
