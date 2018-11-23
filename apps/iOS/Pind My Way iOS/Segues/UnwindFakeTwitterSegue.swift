//
//  UnwindFakeTwitterSegue.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 22/11/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

class UnwindFakeTwitterSegue: UIStoryboardSegue {
    
    override func perform() {
        let mapViewController = self.destination as! ViewController
        
        let goViewControllerView = self.source.view!
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let centerX = screenWidth * 0.5
        let centerY = screenHeight * 0.5
        
        let window = UIApplication.shared.keyWindow
        
        mapViewController.view.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        mapViewController.view.alpha = 0
        
        window?.insertSubview(mapViewController.view, aboveSubview: goViewControllerView)
        
        UIView.animateKeyframes(withDuration: 0.8, delay: 0, options: .calculationModeLinear, animations: {
            // Add animations
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0, animations: {
                // Sets it to the state it was at before
                mapViewController.animationView.frame = CGRect(x: -curvatureLeeway, y: -curvatureLeeway*screenHeight/screenWidth, width: 2*curvatureLeeway+screenWidth, height: 2*curvatureLeeway*screenHeight/screenWidth+screenHeight)
                
                mapViewController.goControlView.frame = CGRect(x: -curvatureLeeway-goControlViewBezel, y: (-curvatureLeeway)*screenHeight/screenWidth-goControlViewBezel, width: 2*(goControlViewBezel+curvatureLeeway)+screenWidth, height: 2*(curvatureLeeway)*screenHeight/screenWidth+2*goControlViewBezel+screenHeight)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25, animations: {
                mapViewController.view.alpha = 1
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.55, animations: {
                mapViewController.animationView.frame = CGRect(x: centerX-75/2+goControlViewBezel, y: centerY-75/2+goControlViewBezel, width: 75-goControlViewBezel*2, height: 75-goControlViewBezel*2)
                
                mapViewController.goControlView.frame = CGRect(origin: CGPoint(x: centerX-(75/2), y: centerY-(75/2)), size: CGSize(width: 75, height: 75))
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2, animations: {
                mapViewController.animationView.frame = CGRect(x: screenWidth-16-75/2, y: screenHeight-16-75/2, width: 1, height: 1)
                
                mapViewController.goControlView.center = CGPoint(x: screenWidth-16-75/2, y: screenHeight-16-75/2)
            })
        }, completion: { _ in
            
            // Rehides the dodgy pixel
            mapViewController.animationView.isHidden = true
            mapViewController.animationView.layer.zPosition = -1
            
            self.destination.dismiss(animated: false, completion: nil)
        })
    }
    
}
