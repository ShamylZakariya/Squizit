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

	var fill:Fill {
		didSet {
			sync()
		}
	}

	required init(coder aDecoder: NSCoder!) {
		self.fill = Fill.Pencil
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

	func nextPlayer( t:AnyObject ) {
		if let player = self.player {
			if player < self.numPlayers - 1 {
				self.player = player+1
			} else {
				matchDone()
			}
		}
	}

	func usePencil( t:AnyObject ) {
		self.fill = Fill.Pencil
	}

	func useBrush( t:AnyObject ) {
		self.fill = Fill.Brush
	}

	func useEraser( t:AnyObject ) {
		self.fill = Fill.Eraser
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

//		navigationItem.rightBarButtonItems = [
//			UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Plain, target: self, action: "nextPlayer:"),
//			UIBarButtonItem(title: "Pencil", style: UIBarButtonItemStyle.Plain, target: self, action: "usePencil:"),
//			UIBarButtonItem(title: "Brush", style: UIBarButtonItemStyle.Plain, target: self, action: "useBrush:"),
//			UIBarButtonItem(title: "Eraser", style: UIBarButtonItemStyle.Plain, target: self, action: "useEraser:")
//		]

		matchView.match = match;
		matchView.player = player
	}

	// MARK: Private

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
		}
	}

}