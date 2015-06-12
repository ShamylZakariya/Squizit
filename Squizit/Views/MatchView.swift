//
//  MatchView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/15/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

let MatchViewDrawingDidChangeNotification = "MatchViewDrawingDidChangeNotification"
let MatchViewDrawingDidChangePlayerUserInfoKey = "MatchViewDrawingDidChangePlayerUserInfoKey"

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

	func screenRectForDrawing( maybeIndex:Int? ) -> CGRect? {

		if let match = self.match {
			if let index = maybeIndex {
				return match.viewports[index]
			}
		}

		return nil
	}

	// MARK: UIView Overrides

	override func drawRect(rect: CGRect) {
		let ctx = UIGraphicsGetCurrentContext()
		CGContextClipToRect(ctx, rect)

		if let match = self.match {
			for (i,drawing) in enumerate(match.drawings) {
				_controllers[i].draw(ctx)
			}
		}
	}

	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		if touches.count > 1 {
			return
		}

		if let player = self.player {
			let touch = touches.first! as! UITouch
			let location = touch.locationInView(self)
			_controllers[player].touchBegan(location)
			_tracking = true
		}
	}

	override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {

		if !_tracking {
			return
		}

		let touch = touches.first! as! UITouch
		let location = touch.locationInView(self)
		_controllers[player!].touchMoved(location)
	}

	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {

		if !_tracking {
			return
		}

		_controllers[player!].touchEnded()
		_tracking = false
		notifyDrawingChanged()
	}

	override func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
		touchesEnded(touches, withEvent: event)
	}


	// MARK: Private

	private func notifyDrawingChanged() {
		if let player = self.player {
			NSNotificationCenter.defaultCenter().postNotificationName(MatchViewDrawingDidChangeNotification, object: self, userInfo: [
				MatchViewDrawingDidChangePlayerUserInfoKey: player
			])
		}
	}

	private func configure(){
		_controllers = []
		if let match = self.match {
			for (i,drawing) in enumerate(match.drawings) {
				let adapter = DrawingInputController()
				adapter.drawing = drawing
				adapter.view = self
				adapter.viewport = match.viewports[i]

				_controllers.append(adapter)
			}
		}
	}
}