//
//  MatchViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/17/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class MatchViewController : UIViewController {

	@IBOutlet var matchView: MatchView!
	var toolSelector:DrawingToolSelector!
	var turnFinishedButton:UIButton!
	var shieldViews:[MatchShieldView] = []
	var endOfMatchGestureRecognizer:UITapGestureRecognizer!

	var match:Match? {
		didSet {
			if matchView != nil {
				matchView.match = self.match
			}
		}
	}

	var player:Int? {
		didSet {
			syncToPlayer()
		}
	}

	var numPlayers:Int {
		if let match = self.match {
			return match.drawings.count
		}

		return 0
	}

	var fill:Fill = Fill.Pencil {
		didSet {
			syncToPlayer()
		}
	}

	func undo() {
		if let match = self.match {
			if let player = self.player {
				matchView.controllers[player].undo()
			}
		}
	}

	func clear() {

		if let match = matchView.match {
			if let player = matchView.player {
				match.drawings[player].clear()
			}
		}

		matchView.setNeedsDisplay()
	}

	func matchDone() {
		println("Match done!")
		endOfMatchGestureRecognizer.enabled = true
	}

	// MARK: Actions & Gestures

	dynamic func eraseDrawing( t:AnyObject ) {
		clear()
	}

	dynamic func turnFinished( t:AnyObject ) {
		if let player = self.player {
			if player < self.numPlayers - 1 {
				self.player = player+1
			} else {
				self.player = nil
				matchDone()
			}

			UIView.animateWithDuration(0.3, animations: { [unowned self] () -> Void in
				self.layoutSubviewsForCurrentMatchState()
			})
		}
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
			switch idx {
				case 0: self.fill = Fill.Pencil
				case 1: self.fill = Fill.Brush
				case 2: self.fill = Fill.Eraser
				default: break;
			}
		}
	}

	dynamic func exitMatch( sender:UITapGestureRecognizer ) {
		presentingViewController.dismissViewControllerAnimated(true, completion: nil)
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
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let paperColor = UIColor( patternImage: UIImage(named: "paper-bg"))
		matchView.backgroundColor = paperColor

		var tgr = UITapGestureRecognizer(target: self, action: "eraseDrawing:")
		tgr.numberOfTapsRequired = 2
		tgr.numberOfTouchesRequired = 1
		matchView.addGestureRecognizer(tgr)

		// this will be enabled only when the match is complete
		endOfMatchGestureRecognizer = UITapGestureRecognizer(target: self, action: "exitMatch:")
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
		toolSelector.addTool("Pencil", icon: UIImage(named: "tool-pen-icon"))
		toolSelector.addTool("Brush", icon: UIImage(named: "tool-brush-icon"))
		toolSelector.addTool("Eraser", icon: UIImage(named: "tool-eraser-icon"))
		toolSelector.addTarget(self, action: "toolSelected:", forControlEvents: UIControlEvents.ValueChanged)
		toolSelector.tintColor = UIColor.whiteColor()
		view.addSubview(toolSelector)

		// create the turn-finished button

		turnFinishedButton = SquizitThemeButton.buttonWithType(UIButtonType.Custom) as UIButton
		turnFinishedButton.setTitle(NSLocalizedString("Next", comment: "UserFinishedRound" ).uppercaseString, forState: UIControlState.Normal)
		turnFinishedButton.addTarget(self, action: "turnFinished:", forControlEvents: UIControlEvents.TouchUpInside)
		turnFinishedButton.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
		turnFinishedButton.tintColor = UIColor.whiteColor()
		view.addSubview(turnFinishedButton)


		matchView.match = match
		matchView.player = player
		toolSelector.selectedToolIndex = 0
	}

	override func viewWillLayoutSubviews() {
		layoutSubviewsForCurrentMatchState()
	}

	// MARK: Private

	private func layoutSubviewsForCurrentMatchState() {
		if let match = self.match {
			if let player = self.player {

				toolSelector.alpha = 1
				turnFinishedButton.alpha = 1

				switch match.drawings.count {
					case 2: layoutSubviewsForTwoPlayers(player)
					case 3: layoutSubviewsForThreePlayers(player)
					default: break;
				}
			} else {
				layoutSubviewsForEndOfMatch()
			}
		}
	}

	private func layoutSubviewsForTwoPlayers( currentPlayer:Int ) {

		if let match = self.match {
			let bounds = view.bounds
			let margin = 2 * match.overlap
			var toolSelectorRect = CGRectZero
			var turnFinishedButtonCenter = CGPointZero

			// two player game only needs one shield view
			shieldViews[0].hidden = false
			shieldViews[1].hidden = true
			shieldViews[1].frame = CGRectZero
			shieldViews[0].topMargin = 0
			shieldViews[0].bottomMargin = 0

			switch currentPlayer {

				case 0:
					toolSelectorRect = CGRect(x: 0, y: bounds.midY, width: bounds.width, height: bounds.height/4)
					turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: bounds.midY + bounds.height/4 + bounds.height/8 )
					shieldViews[0].frame = matchView.rectForPlayer(1)!
					shieldViews[0].topMargin = margin

				case 1:
					toolSelectorRect = CGRect(x: 0, y: bounds.midY/2, width: bounds.width, height: bounds.height/4)
					turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: bounds.height/8 )
					shieldViews[0].frame = matchView.rectForPlayer(0)!
					shieldViews[0].bottomMargin = margin

				default: break;
			}

			toolSelector.frame = toolSelectorRect
			turnFinishedButton.center = turnFinishedButtonCenter

		}
	}

	private func layoutSubviewsForThreePlayers( currentPlayer:Int ) {

		if let match = self.match {
			let bounds = view.bounds
			let margin = 2 * match.overlap
			var toolSelectorRect = CGRectZero
			var turnFinishedButtonCenter = CGPointZero
			var thirdHeight = bounds.size.height / 3.0
			var twoThirdsHeight = bounds.size.height * 2.0 / 3.0
			var sixthHeight = thirdHeight / 2.0

			shieldViews[0].hidden = false
			shieldViews[1].hidden = false
			shieldViews[0].topMargin = 0
			shieldViews[0].bottomMargin = 0
			shieldViews[1].topMargin = 0
			shieldViews[1].bottomMargin = 0

			switch currentPlayer {

				case 0:
					// place controls over middle third
					toolSelectorRect = CGRect(x: 0, y: thirdHeight, width: bounds.width, height: sixthHeight)
					turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: thirdHeight + 1.5 * sixthHeight )
					shieldViews[0].frame = matchView.rectForPlayer(1)!
					shieldViews[0].topMargin = margin
					shieldViews[1].frame = matchView.rectForPlayer(2)!

				case 1:
					// place controls over bottom third
					toolSelectorRect = CGRect(x: 0, y: twoThirdsHeight, width: bounds.width, height: sixthHeight)
					turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: twoThirdsHeight + 1.5 * sixthHeight )
					shieldViews[0].frame = matchView.rectForPlayer(0)!
					shieldViews[0].bottomMargin = margin
					shieldViews[1].frame = matchView.rectForPlayer(2)!
					shieldViews[1].topMargin = margin

				case 2:
					// place controls over middle third
					toolSelectorRect = CGRect(x: 0, y: thirdHeight, width: bounds.width, height: sixthHeight)
					turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: thirdHeight + 1.5 * sixthHeight )
					shieldViews[0].frame = matchView.rectForPlayer(0)!
					shieldViews[1].frame = matchView.rectForPlayer(1)!
					shieldViews[1].bottomMargin = margin

				default: break;
			}

			toolSelector.frame = toolSelectorRect
			turnFinishedButton.center = turnFinishedButtonCenter
		}
	}

	private func layoutSubviewsForEndOfMatch() {
		if let match = self.match {
			switch match.drawings.count {
				case 2:
					let height = shieldViews[0].frame.height
					shieldViews[0].frame = shieldViews[0].frame.rectByOffsetting(dx: 0, dy: -height)

				case 3:
					let height = shieldViews[0].frame.height + shieldViews[1].frame.height
					shieldViews[0].frame = shieldViews[0].frame.rectByOffsetting(dx: 0, dy: -height)
					shieldViews[1].frame = shieldViews[1].frame.rectByOffsetting(dx: 0, dy: -height)

				default: break;
			}
		}

		toolSelector.alpha = 0
		turnFinishedButton.alpha = 0
	}

	private func syncToPlayer() {
		if matchView != nil {
			matchView.player = self.player

			for controller in matchView.controllers {
				controller.fill = self.fill
			}
		}
	}

}