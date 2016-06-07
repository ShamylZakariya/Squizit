//
//  SaveToGalleryTransitionManager.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/26/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class SaveToGalleryTransitionManager: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate  {
    
    private var presenting = false

	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

		let presenting = self.presenting
		let scale:CGFloat = 1.075
		let bigScale = CGAffineTransformMakeScale(scale, scale)

		let container = transitionContext.containerView()!
		let baseView = transitionContext.viewForKey(presenting ? UITransitionContextFromViewKey : UITransitionContextToViewKey)!
		let dialogView = transitionContext.viewForKey(presenting ? UITransitionContextToViewKey : UITransitionContextFromViewKey)!
		let dialogViewController = transitionContext.viewControllerForKey(presenting ? UITransitionContextToViewControllerKey : UITransitionContextFromViewControllerKey)! as! SaveToGalleryViewController

		container.addSubview(baseView)
		container.addSubview(dialogView)

		if presenting {
			dialogView.alpha = 0
			dialogViewController.dialogView.transform = bigScale
		}

		let duration = self.transitionDuration(transitionContext)

		UIView.animateWithDuration(duration,
			delay: 0.0,
			usingSpringWithDamping: 0.7,
			initialSpringVelocity: 0,
			options: [],
			animations: {

				if presenting {
					dialogView.alpha = 1
				} else {
					dialogViewController.dialogView.transform = bigScale
				}

			},
			completion: nil )

		UIView.animateWithDuration(duration,
			delay: duration/6,
			usingSpringWithDamping: 0.7,
			initialSpringVelocity: 0.5,
			options: [],
			animations: {
				if presenting {
					dialogViewController.dialogView.transform = CGAffineTransformIdentity
				} else {
					dialogView.alpha = 0
				}
			},
			completion: { finished in
				transitionContext.completeTransition(true)
			})

	}


    // return how many seconds the transiton animation will take
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    // MARK: UIViewControllerTransitioningDelegate protocol methods
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}
