//
//  FakeTwitterSegue.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 22/11/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

let goControlViewBezel: CGFloat = 5
let curvatureLeeway: CGFloat = 25

class FakeTwitterSegue: UIStoryboardSegue {
    override func perform() {
        let mapViewController = self.source as! ViewController
        
        let goViewControllerView = self.destination.view!
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let centerX = screenWidth * 0.5
        let centerY = screenHeight * 0.5
        
        let window = UIApplication.shared.keyWindow
        
        goViewControllerView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        goViewControllerView.alpha = 0
        
        window?.insertSubview(goViewControllerView, aboveSubview: mapViewController.view)
        
        let goControlRadius = mapViewController.goControlView.frame.width * 0.5
        
        // Unhides the dodgy pixel, this must be done now
        mapViewController.animationView.isHidden = false
        mapViewController.animationView.layer.zPosition = 2
        
        UIView.animateKeyframes(withDuration: 1, delay: 0, options: .calculationModeLinear, animations: {
            // Add animations
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                mapViewController.goControlView.center = CGPoint(x: centerX, y: centerY)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0, animations: {
                
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2, animations: {
                let animationViewRadius = goControlRadius-goControlViewBezel
                
                mapViewController.animationView.frame = CGRect(x: centerX-animationViewRadius, y: centerY-animationViewRadius, width: animationViewRadius*2, height: animationViewRadius*2)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.4, animations: {
                mapViewController.animationView.frame = CGRect(x: -curvatureLeeway, y: -curvatureLeeway, width: 2*curvatureLeeway+screenWidth, height: 2*curvatureLeeway+screenHeight)
                
                mapViewController.goControlView.frame = CGRect(x: -curvatureLeeway-goControlViewBezel, y: -curvatureLeeway-goControlViewBezel, width: 2*(goControlViewBezel+curvatureLeeway)+screenWidth, height: 2*(goControlViewBezel+curvatureLeeway)+screenHeight)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2, animations: {
                goViewControllerView.alpha = 1
            })
        }, completion: { _ in
            self.source.present(self.destination, animated: false, completion: nil)
        })
    }
}
