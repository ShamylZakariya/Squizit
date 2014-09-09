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
	@IBOutlet weak var borderView: UIImageView!

	override func viewDidLoad() {
		var tgr = UITapGestureRecognizer(target: self, action: "showTestDrawingView:")
		tgr.numberOfTapsRequired = 2
		tgr.numberOfTouchesRequired = 2
		self.view.addGestureRecognizer(tgr)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Fade)

		contentView.layer.opacity = 0
		contentView.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1)
		borderView.layer.opacity = 0
		borderView.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

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
			completion: nil)
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

		switch ( segue.identifier ) {
			case "showGallery":
				let navVC = segue.destinationViewController as UINavigationController
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

				let matchVC = segue.destinationViewController as MatchViewController
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

	internal dynamic func showTestDrawingView( sender:AnyObject ) {
		performSegueWithIdentifier("showTestDrawingView", sender: sender)
	}

	// MARK: GalleryViewControllerDelegate

	func galleryDidDismiss( galleryViewController:AnyObject ) {
		dismissViewControllerAnimated(true, completion: nil)
	}
}