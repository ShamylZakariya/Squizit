//
//  RootViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/18/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class RootViewController : UIViewController, GalleryViewControllerDelegate {


	@IBOutlet weak var twoPlayersButton: UIButton!
	@IBOutlet weak var threePlayersButton: UIButton!
	@IBOutlet weak var galleryButton: UIButton!
	@IBOutlet weak var contentView: UIView!
	@IBOutlet weak var borderView: RootBorderView!

	override func viewDidLoad() {

		#if DEBUG
			var tgr = UITapGestureRecognizer(target: self, action: "showTestDrawingView:")
			tgr.numberOfTapsRequired = 2
			tgr.numberOfTouchesRequired = 2
			self.view.addGestureRecognizer(tgr)
		#endif
	}

	private var playedIntroAnimation:Bool = false

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Fade)

		if !playedIntroAnimation {
			contentView.layer.opacity = 0
			contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1)
			borderView.layer.opacity = 0
			borderView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
		}

		switch UIDevice.currentDevice().userInterfaceIdiom {
			case UIUserInterfaceIdiom.Pad:
				borderView.borderSize = 32

			case UIUserInterfaceIdiom.Phone:
				borderView.borderSize = 6

			default:
				break;
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		if !playedIntroAnimation {
			UIView.animateWithDuration(1.5,
				delay: 0.0,
				usingSpringWithDamping: CGFloat(0.4),
				initialSpringVelocity: CGFloat(0.0),
				options: UIViewAnimationOptions.AllowUserInteraction,
				animations: {
					[unowned self] () -> Void in
					self.contentView.layer.opacity = 1
					self.contentView.layer.transform = CATransform3DMakeScale(1, 1, 1)
					self.borderView.layer.opacity = 1
					self.borderView.layer.transform = CATransform3DMakeScale(1, 1, 1)
				},
				completion: {
					[unowned self] finished in
					self.playedIntroAnimation = true
				})
		}
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	private var transitionManager = FullscreenModalTransitionManager()

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

		let destinationVC = segue.destinationViewController as UIViewController
		destinationVC.transitioningDelegate = transitionManager

		switch ( segue.identifier ) {
			case "showGallery":
				let navVC = destinationVC as UINavigationController
				if let galleryVC = navVC.childViewControllers.first as? GalleryViewController {
					galleryVC.store = (UIApplication.sharedApplication().delegate as? AppDelegate)!.galleryStore
					galleryVC.delegate = self
				} else {
					assertionFailure("Unable to extract GalleryViewController from segue")
				}

			case "beginTwoPlayerMatch", "beginThreePlayerMatch":
				var players = 0
				if segue.identifier == "beginTwoPlayerMatch" {
					players = 2
				} else {
					players = 3
				}

				let matchVC = destinationVC as MatchViewController
				let screenBounds = UIScreen.mainScreen().bounds
				matchVC.match = Match(players: players, stageSize: CGSize(width: screenBounds.width, height: screenBounds.height), overlap: 4)

			case "showTestDrawingView":
				break;

			default:
				assertionFailure("Unrecognized segue")
				break;

		}
	}

	// MARK: Actions

	dynamic func showTestDrawingView( sender:AnyObject ) {
		performSegueWithIdentifier("showTestDrawingView", sender: sender)
	}

	// MARK: GalleryViewControllerDelegate

	func galleryDidDismiss( galleryViewController:AnyObject ) {
		dismissViewControllerAnimated(true, completion: nil)
	}
}