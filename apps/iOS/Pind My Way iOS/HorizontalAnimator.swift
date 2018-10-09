//
//  HorizontalAnimator.swift
//  Pind My Way iOS
//
//  Created by Atto Allas on 09/10/2018.
//  Copyright © 2018 Atto Allas. All rights reserved.
//

import UIKit

class HorizontalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration = 0.4
    let forwards: Bool
    
    init(goingForwards forwards: Bool = true) {
        self.forwards = forwards
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        let firstClassView = transitionContext.view(forKey: .from)!
        let secondClassView = transitionContext.view(forKey: .to)!
        
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        let xMultiplier: CGFloat = forwards ? 1 : -1
        
        secondClassView.frame = CGRect(x: xMultiplier*screenWidth, y: 0, width: screenWidth, height: screenHeight)
        
        containerView.insertSubview(secondClassView, aboveSubview: firstClassView)
        
        UIView.animate(withDuration: duration, animations: { () -> Void in
            
            firstClassView.frame = (firstClassView.frame.offsetBy(dx: xMultiplier * -screenWidth, dy: 0))
            secondClassView.frame = (secondClassView.frame.offsetBy(dx: xMultiplier * -screenWidth, dy: 0))
            
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
        
    }
    
    
}
