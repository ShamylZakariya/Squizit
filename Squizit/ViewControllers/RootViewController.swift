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
	@IBOutlet weak var howToPlayButton: SquizitThemeButton!
	@IBOutlet weak var twitterButton: SquizitThemeButton!
	@IBOutlet weak var extraButtonsBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var extraButtonsHeightConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var contentViewCenterYConstraint: NSLayoutConstraint!

	override func viewDidLoad() {

		twitterButton.bordered = false
		howToPlayButton.bordered = false

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
			contentView.alpha = 0
			contentView.transform = CGAffineTransformMakeScale(0.9, 0.9)
			borderView.alpha = 0
			borderView.transform = CGAffineTransformMakeScale(1.1, 1.1)

			howToPlayButton.alpha = 0
			twitterButton.alpha = 0
		}
	}

	override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
		if traitCollection.horizontalSizeClass == .Compact || traitCollection.verticalSizeClass == .Compact {
			borderView.borderSize = 6
			borderView.edgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
		} else {
			borderView.borderSize = 32
			borderView.edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		}

		if traitCollection.verticalSizeClass == .Compact {
			extraButtonsHeightConstraint.constant = 22
			contentViewCenterYConstraint.constant = 22
		} else {
			contentViewCenterYConstraint.constant = 0
			extraButtonsHeightConstraint.constant = 44
		}

		extraButtonsBottomConstraint.constant = CGFloat(3 * borderView.borderSize)
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
					self.contentView.alpha = 1
					self.contentView.transform = CGAffineTransformIdentity
					self.borderView.alpha = 1
					self.borderView.transform = CGAffineTransformIdentity
				},
				completion: {
					[unowned self] finished in
					self.playedIntroAnimation = true
				})

			UIView.animateWithDuration(0.5,
				delay: 1.0,
				options: .AllowUserInteraction,
				animations: { () -> Void in
					self.howToPlayButton.alpha = 0.5
					self.twitterButton.alpha = 0.5
				},
				completion: nil)
		}
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func prefersStatusBarHidden() -> Bool {
		return false
	}

	private var transitionManager = FullscreenModalTransitionManager()

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

		let destinationVC = segue.destinationViewController as! UIViewController
		destinationVC.transitioningDelegate = transitionManager

		if let identifier = segue.identifier {
			switch ( identifier ) {
				case "showGallery":
					let navVC = destinationVC as! UINavigationController
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

					let matchVC = destinationVC as! MatchViewController
					let screenBounds = UIScreen.mainScreen().bounds
					matchVC.match = Match(players: players, stageSize: CGSize(width: screenBounds.width, height: screenBounds.height), overlap: 4)

				case "showTestDrawingView", "showHowToPlay":
					// no setup needed for these two
					break;

				default:
					assertionFailure("Unrecognized segue")
					break;
			}
		}
	}

	// MARK: Actions

	@IBAction func onTwitterButtonTapped(sender: AnyObject) {
		if let twitterURL = NSURL(string: "https://twitter.com/squizitapp") {
			UIApplication.sharedApplication().openURL(twitterURL)
		}
	}

	dynamic func showTestDrawingView( sender:AnyObject ) {
		performSegueWithIdentifier("showTestDrawingView", sender: sender)
	}

	// MARK: GalleryViewControllerDelegate

	func galleryDidDismiss( galleryViewController:AnyObject ) {
		dismissViewControllerAnimated(true, completion: nil)
	}
}