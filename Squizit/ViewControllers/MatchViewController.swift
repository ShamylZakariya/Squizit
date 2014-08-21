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

	var match:Match? {
		didSet {
			configure()
		}
	}

	var player:Int? {
		didSet {
			sync();
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
			sync()
		}
	}

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		edgesForExtendedLayout = UIRectEdge.None
		extendedLayoutIncludesOpaqueBars = true
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
	}

	// MARK: Actions & Gestures

	func eraseDrawing( t:AnyObject ) {
		clear()
	}

	func turnFinished( t:AnyObject ) {
		if let player = self.player {
			if player < self.numPlayers - 1 {
				self.player = player+1
			} else {
				self.player = nil
				turnFinishedButton.setTitle(NSLocalizedString("Complete", comment: "EndOfMatch" ).uppercaseString, forState: UIControlState.Normal)
				matchDone()
			}
		}
	}

	func swipeLeft( t:UISwipeGestureRecognizer ) {

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

	func toolSelected( sender:DrawingToolSelector ) {
		if let idx = sender.selectedToolIndex {
			switch idx {
				case 0: self.fill = Fill.Pencil
				case 1: self.fill = Fill.Brush
				case 2: self.fill = Fill.Eraser
				default: break;
			}
		}
	}

	// MARK: UIKit Overrides

	override func viewWillAppear(animated: Bool) {
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

		var sgr = UISwipeGestureRecognizer(target: self, action: "swipeLeft:" )
		sgr.direction = .Left
		sgr.numberOfTouchesRequired = 2
		matchView.addGestureRecognizer(sgr)

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

		turnFinishedButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
		turnFinishedButton.setTitle(NSLocalizedString("Next", comment: "UserFinishedRound" ).uppercaseString, forState: UIControlState.Normal)
		turnFinishedButton.titleLabel.font = UIFont(name: "Avenir-Light", size: UIFont.buttonFontSize())
		turnFinishedButton.tintColor = UIColor.whiteColor()
		turnFinishedButton.addTarget(self, action: "turnFinished:", forControlEvents: UIControlEvents.TouchUpInside)
		turnFinishedButton.layer.cornerRadius = 0
		turnFinishedButton.layer.borderWidth = 1
		turnFinishedButton.layer.borderColor = UIColor.whiteColor().CGColor
		turnFinishedButton.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
		view.addSubview(turnFinishedButton)

		matchView.match = match
		matchView.player = player
		toolSelector.selectedToolIndex = 0
	}

	override func viewWillLayoutSubviews() {

		if let match = self.match {
			if let player = self.player {
				switch match.drawings.count {
					case 2: layoutSubviewsForTwoPlayers(player)
					case 3: layoutSubviewsForThreePlayers(player)
					default: break;
				}
			} else {
				toolSelector.hidden = true
			}
		}
	}

	// MARK: Private

	private func layoutSubviewsForTwoPlayers( currentPlayer:Int ) {

		let bounds = view.bounds
		var toolSelectorRect = CGRectZero
		var turnFinishedButtonCenter = CGPointZero

		switch currentPlayer {

			case 0:
				toolSelectorRect = CGRect(x: 0, y: bounds.midY, width: bounds.width, height: bounds.height/4)
				turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: bounds.midY + bounds.height/4 + bounds.height/8 )

			case 1:
				toolSelectorRect = CGRect(x: 0, y: bounds.midY/2, width: bounds.width, height: bounds.height/4)
				turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: bounds.height/8 )

			default: break;
		}

		toolSelector.frame = toolSelectorRect
		turnFinishedButton.center = turnFinishedButtonCenter
	}

	private func layoutSubviewsForThreePlayers( currentPlayer:Int ) {
		let bounds = view.bounds
		var toolSelectorRect = CGRectZero
		var turnFinishedButtonCenter = CGPointZero
		var thirdHeight = bounds.size.height / 3.0
		var twoThirdsHeight = bounds.size.height * 2.0 / 3.0
		var sixthHeight = thirdHeight / 2.0


		switch currentPlayer {

			case 0,2:
				// place controls over middle third
				toolSelectorRect = CGRect(x: 0, y: thirdHeight, width: bounds.width, height: sixthHeight)
				turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: thirdHeight + 1.5 * sixthHeight )

			case 1:
				// place controls over bottom third
				toolSelectorRect = CGRect(x: 0, y: twoThirdsHeight, width: bounds.width, height: sixthHeight)
				turnFinishedButtonCenter = CGPoint( x: bounds.midX, y: twoThirdsHeight + 1.5 * sixthHeight )

			default: break;
		}

		toolSelector.frame = toolSelectorRect
		turnFinishedButton.center = turnFinishedButtonCenter
	}

	private func configure() {
		if matchView != nil {
			matchView.match = self.match
		}
	}

	private func sync() {
		if matchView != nil {
			matchView.player = self.player

			for controller in matchView.controllers {
				controller.fill = self.fill
			}

			view.setNeedsLayout()
		}
	}
}