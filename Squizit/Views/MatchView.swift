//
//  MatchView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/15/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class MatchView : UIView {

	var match:Match? {
		didSet {
			configure()
			setNeedsDisplay()
		}
	}

	var player:Int? {
		didSet {
			setNeedsDisplay()
		}
	}

	private var _controllers:[DrawingInputController] = []
	private var _tracking:Bool = false

	var controllers:[DrawingInputController] { return _controllers }

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
	}

	func rectForPlayer( maybeIndex:Int? ) -> CGRect? {

		if let match = self.match {
			if let index = maybeIndex {
				return match.rectForPlayer(index)
			}
		}

		return nil
	}

	// MARK: UIView Overrides

	override func drawRect(rect: CGRect) {
		let ctx = UIGraphicsGetCurrentContext()
		if let match = self.match {
			let drawings = enumerate(match.drawings)

			// paint each drawing
			for (i,drawing) in drawings {
				let transform = match.transforms[i]
				_controllers[i].draw(ctx)
			}
		}
	}

	override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {

		if touches.count > 1 {
			return
		}

		if let player = self.player {
			let location = touches.anyObject().locationInView(self)
			_controllers[player].touchBegan(location)
			_tracking = true
		}
	}

	override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {

		if !_tracking {
			return
		}

		let location = touches.anyObject().locationInView(self)
		_controllers[player!].touchMoved(location)
	}

	override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {

		if !_tracking {
			return
		}

		_controllers[player!].touchEnded()
		_tracking = false
	}

	override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
		touchesEnded(touches, withEvent: event)
	}


	// MARK: Private

	private func configure(){
		_controllers = []
		if let match = self.match {
			for (i,drawing) in enumerate(match.drawings) {
				let adapter = DrawingInputController()
				adapter.drawing = drawing
				adapter.view = self
				adapter.transform = match.transforms[i]

				_controllers.append(adapter)
			}
		}
	}
}