//
//  MatchViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/17/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {

	func rectByAddingTopMargin( m:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y + m, width: size.width, height: size.height - m )
	}

	func rectByAddingBottomMargin( m:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height - m )
	}

	func rectByAddingMargins( topMargin:CGFloat, bottomMargin:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y + topMargin, width: size.width, height: size.height - topMargin - bottomMargin )
	}

}

class MatchViewController : UIViewController {

	@IBOutlet var matchView: MatchView!

	var toolSelector:DrawingToolSelector!
	var stepForwardButton:UIButton!
	var shieldViews:[MatchShieldView] = []
	var endOfMatchGestureRecognizer:UITapGestureRecognizer!

	var match:Match?

	/*
		current game step
		if step < numPlayers the match is active ( see matchActive:Bool )
		if step == numPlayers we're presenting the final drawing to the player
		if step == numPlayers+1 we're showing the save dialog and exiting
	*/
	var step:Int = 0 {
		didSet {
			if matchActive {
				matchView.player = self.step
			} else if step == numPlayers {
				// enable the
				endOfMatchGestureRecognizer.enabled = true
			} else {
				presentingViewController.dismissViewControllerAnimated(true, completion: nil)
			}

			syncToMatchState_Animate()
		}
	}

	var numPlayers:Int {
		if let match = self.match {
			return match.drawings.count
		}

		return 0
	}

	var matchActive:Bool {
		return step < numPlayers
	}

	func undo() {
		if let match = self.match {
			if matchActive {
				matchView.controllers[step].undo()
			}
		}
	}

	func clear() {

		if let match = matchView.match {
			if matchActive {
				match.drawings[step].clear()
			}
		}

		matchView.setNeedsDisplay()
	}

	// MARK: Actions & Gestures

	dynamic func eraseDrawing( t:AnyObject ) {
		clear()
	}

	dynamic func stepForward( t:AnyObject ) {
		step++
	}

	dynamic func swipeLeft( t:UISwipeGestureRecognizer ) {

		//
		//	NOTE: swipe is recognized by the view and a stroke is drawn
		//	the undo action undoes that stroke immediately.
		//
		//	the hack fix is to call undo() twice
		//	the correct fix is to have the drawing view ignore the touch if it's
		//	part of a swipe gesture.
		//

		undo()
		undo()
	}

	dynamic func toolSelected( sender:DrawingToolSelector ) {
		if let idx = sender.selectedToolIndex {
			var fill = Fill.Pencil
			switch idx {
				case 0: fill = Fill.Pencil
				case 1: fill = Fill.Brush
				case 2: fill = Fill.Eraser
				default: break;
			}

			for controller in matchView.controllers {
				controller.fill = fill
			}
		}
	}

	// MARK: UIKit Overrides

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		edgesForExtendedLayout = UIRectEdge.None
		extendedLayoutIncludesOpaqueBars = true
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		endOfMatchGestureRecognizer.enabled = false
		matchView.match = match
		matchView.player = step
		toolSelector.selectedToolIndex = 0
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = SquizitTheme.matchBackgroundColor()

		matchView.backgroundColor = SquizitTheme.paperBackgroundColor()
		matchView.layer.shadowOffset = CGSize(width: 0, height: 3)
		matchView.layer.shadowColor = UIColor.blackColor().CGColor
		matchView.layer.shadowOpacity = 0
		matchView.layer.shadowRadius = 10

		var tgr = UITapGestureRecognizer(target: self, action: "eraseDrawing:")
		tgr.numberOfTapsRequired = 2
		tgr.numberOfTouchesRequired = 1
		matchView.addGestureRecognizer(tgr)

		// this will be enabled only when the match is complete
		endOfMatchGestureRecognizer = UITapGestureRecognizer(target: self, action: "stepForward:")
		endOfMatchGestureRecognizer.numberOfTapsRequired = 1
		endOfMatchGestureRecognizer.enabled = false
		matchView.addGestureRecognizer(endOfMatchGestureRecognizer)

		var sgr = UISwipeGestureRecognizer(target: self, action: "swipeLeft:" )
		sgr.direction = .Left
		sgr.numberOfTouchesRequired = 2
		matchView.addGestureRecognizer(sgr)

		// create the shield views

		var sv = MatchShieldView(frame: CGRectZero)
		view.addSubview(sv)
		shieldViews.append(sv)

		sv = MatchShieldView(frame: CGRectZero)
		view.addSubview(sv)
		shieldViews.append(sv)

		// create the tool selector

		toolSelector = DrawingToolSelector(frame: CGRectZero)
		toolSelector.orientation = .Horizontal
		toolSelector.addTool("Pencil", icon: UIImage(named: "tool-pencil"))
		toolSelector.addTool("Brush", icon: UIImage(named: "tool-brush"))
		toolSelector.addTool("Eraser", icon: UIImage(named: "tool-eraser"))
		toolSelector.addTarget(self, action: "toolSelected:", forControlEvents: UIControlEvents.ValueChanged)
		toolSelector.tintColor = UIColor.whiteColor()
		view.addSubview(toolSelector)

		// create the turn-finished button

		stepForwardButton = SquizitThemeButton.buttonWithType(UIButtonType.Custom) as UIButton
		stepForwardButton.setTitle(NSLocalizedString("Next", comment: "UserFinishedRound" ).uppercaseString, forState: UIControlState.Normal)
		stepForwardButton.addTarget(self, action: "stepForward:", forControlEvents: UIControlEvents.TouchUpInside)
		stepForwardButton.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
		stepForwardButton.tintColor = UIColor.whiteColor()
		view.addSubview(stepForwardButton)

		matchView.match = match
		matchView.player = 0
	}

	override func viewWillLayoutSubviews() {
		self.syncToMatchState()
	}

	// MARK: Private

	private func syncToMatchState_Animate() {
		let duration:NSTimeInterval = 0.7
		let delay:NSTimeInterval = 0
		let damping:CGFloat = 0.7
		let initialSpringVelocity:CGFloat = 0
		let options:UIViewAnimationOptions = UIViewAnimationOptions(0)

		UIView.animateWithDuration(duration,
			delay: delay,
			usingSpringWithDamping: damping,
			initialSpringVelocity: initialSpringVelocity,
			options: options,
			animations: { [unowned self] () -> Void in
				self.syncToMatchState()
			},
			completion: nil)
	}

	private func syncToMatchState() {

		if matchActive {

			toolSelector.alpha = 1
			stepForwardButton.alpha = 1
			matchView.layer.shadowOpacity = 0
			matchView.layer.shouldRasterize = false

			switch numPlayers {
				case 2: layoutSubviewsForTwoPlayers(step)
				case 3: layoutSubviewsForThreePlayers(step)
				default: break;
			}

		} else if step == numPlayers {

			shieldViews[0].alpha = 0
			shieldViews[1].alpha = 0
			toolSelector.alpha = 0
			stepForwardButton.alpha = 0

			let angleRange = drand48() * 2.0 - 1.0
			let angle = M_PI * 0.00625 * angleRange
			let scale = CATransform3DMakeScale(0.9, 0.9, 1.0)
			let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
			matchView.layer.transform = CATransform3DConcat(scale, rotation)
			matchView.layer.shouldRasterize = true

			matchView.layer.shadowOpacity = 1

		} else {

		}
	}

	private func layoutSubviewsForTwoPlayers( currentPlayer:Int ) {

		if let match = self.match {
			let bounds = view.bounds
			let margin = 2 * match.overlap
			var toolSelectorRect = CGRectZero
			var stepForwardButtonCenter = CGPointZero

			// two player game only needs one shield view
			shieldViews[0].hidden = false
			shieldViews[1].hidden = true
			shieldViews[1].frame = CGRectZero

			switch currentPlayer {

				case 0:
					toolSelectorRect = CGRect(x: 0, y: bounds.midY, width: bounds.width, height: bounds.height/4)
					stepForwardButtonCenter = CGPoint( x: bounds.midX, y: bounds.midY + bounds.height/4 + bounds.height/8 )
					shieldViews[0].frame = matchView.rectForPlayer(1)!.rectByAddingTopMargin(margin)
					//shieldViews[0].topMargin = margin

				case 1:
					toolSelectorRect = CGRect(x: 0, y: bounds.midY/2, width: bounds.width, height: bounds.height/4)
					stepForwardButtonCenter = CGPoint( x: bounds.midX, y: bounds.height/8 )
					shieldViews[0].frame = matchView.rectForPlayer(0)!.rectByAddingBottomMargin(margin)
					//shieldViews[0].bottomMargin = margin

				default: break;
			}

			toolSelector.frame = toolSelectorRect
			stepForwardButton.center = stepForwardButtonCenter

		}
	}

	private func layoutSubviewsForThreePlayers( currentPlayer:Int ) {

		if let match = self.match {
			let bounds = view.bounds
			let margin = 2 * match.overlap
			var toolSelectorRect = CGRectZero
			var stepForwardButtonCenter = CGPointZero
			var thirdHeight = bounds.size.height / 3.0
			var twoThirdsHeight = bounds.size.height * 2.0 / 3.0
			var sixthHeight = thirdHeight / 2.0

			shieldViews[0].hidden = false
			shieldViews[1].hidden = false
			shieldViews[0].alpha = 1
			shieldViews[1].alpha = 1

			switch currentPlayer {

				case 0:
					// place controls over middle third
					toolSelectorRect = CGRect(x: 0, y: thirdHeight, width: bounds.width, height: sixthHeight)
					stepForwardButtonCenter = CGPoint( x: bounds.midX, y: thirdHeight + 1.5 * sixthHeight )

					// hide shield 1 off top of screen - it will slide down in case 1
					var r = matchView.rectForPlayer(0)!
					r.offset(dx: 0, dy: -r.height )
					shieldViews[0].frame = r

					// shield 2 takes up bottom 2/3
					let r1 = matchView.rectForPlayer(1)!.rectByAddingTopMargin(margin)
					let r2 = matchView.rectForPlayer(2)!
					shieldViews[1].frame = r1.rectByUnion(r2)

				case 1:
					// place controls over top third
					toolSelectorRect = CGRect(x: 0, y: 0, width: bounds.width, height: sixthHeight)
					stepForwardButtonCenter = CGPoint( x: bounds.midX, y: sixthHeight + 0.5 * sixthHeight )
					shieldViews[0].frame = matchView.rectForPlayer(0)!.rectByAddingBottomMargin(margin)
					shieldViews[1].frame = matchView.rectForPlayer(2)!.rectByAddingTopMargin(margin)

				case 2:
					// place controls over middle third
					toolSelectorRect = CGRect(x: 0, y: thirdHeight, width: bounds.width, height: sixthHeight)
					stepForwardButtonCenter = CGPoint( x: bounds.midX, y: thirdHeight + 1.5 * sixthHeight )
					shieldViews[0].frame = matchView.rectForPlayer(0)!
					shieldViews[1].frame = matchView.rectForPlayer(1)!.rectByAddingBottomMargin(margin)

					// shield 1 takes up top 2/3
					let r1 = matchView.rectForPlayer(0)!.rectByAddingTopMargin(margin)
					let r2 = matchView.rectForPlayer(1)!
					shieldViews[0].frame = r1.rectByUnion(r2)

					// slide shield 2 off bottom of screen
					var r = matchView.rectForPlayer(2)!.rectByAddingTopMargin(margin)
					r.offset(dx: 0, dy: r.height )
					shieldViews[1].frame = r

				default: break;
			}

			toolSelector.frame = toolSelectorRect
			stepForwardButton.center = stepForwardButtonCenter
		}
	}
}