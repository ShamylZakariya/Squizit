//
//  FullscreenModalTransitionManager.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/19/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit


class FullscreenModalTransitionManager: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate  {

	private var presenting:Bool = true

	// MARK: UIViewControllerAnimatedTransitioning protocol methods

	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

		// get reference to our fromView, toView and the container view that we should perform the transition in
		let container = transitionContext.containerView()
		let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
		let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!

		let scale:CGFloat = 1.075
		let bigScale = CGAffineTransformMakeScale(scale, scale)
		let smallScale = CGAffineTransformMakeScale(1/scale,1/scale)
		let smallOpacity:CGFloat = 0.5
		let presenting = self.presenting

		if presenting {

			// when presenting, incoming view must be on top
			container.addSubview(fromView)
			container.addSubview(toView)

			toView.transform = bigScale
			toView.opaque = false
			toView.alpha = 0

			fromView.transform = CGAffineTransformIdentity
			fromView.opaque = false
			fromView.alpha = 1
		} else {

			// when !presenting, outgoing view must be on top
			container.addSubview(toView)
			container.addSubview(fromView)

			toView.transform = smallScale
			toView.opaque = false
			toView.alpha = smallOpacity

			fromView.transform = CGAffineTransformIdentity
			fromView.opaque = false
			fromView.alpha = 1
		}


		let duration = self.transitionDuration(transitionContext)

		UIView.animateWithDuration(duration,
			delay: 0.0,
			usingSpringWithDamping: 0.7,
			initialSpringVelocity: 0,
			options: nil,
			animations: {

				if presenting {
					fromView.transform = smallScale
					fromView.alpha = smallOpacity
				} else {
					fromView.transform = bigScale
					fromView.alpha = 0
				}

			},
			completion: { completed in
				// set transform of now hidden view to identity to prevent breakage during rotation
				fromView.transform = CGAffineTransformIdentity
			})

		UIView.animateWithDuration(duration,
			delay: duration/6,
			usingSpringWithDamping: 0.7,
			initialSpringVelocity: 0.5,
			options: nil,
			animations: {
				toView.transform = CGAffineTransformIdentity
				toView.alpha = 1
			},
			completion: { finished in
				transitionContext.completeTransition(true)
			})
	}

	// return how many seconds the transiton animation will take
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
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
