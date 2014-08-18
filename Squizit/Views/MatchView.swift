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

	var player:Int?

	private var _controllers:[DrawingInputController] = []
	private var _tracking:Bool = false

	var controllers:[DrawingInputController] { return _controllers }

	required init(coder aDecoder: NSCoder!) {
		super.init( coder: aDecoder )
	}

	// MARK: UIView Overrides

	override func drawRect(rect: CGRect) {
		let ctx = UIGraphicsGetCurrentContext()
		if let match = self.match {
			for (i,drawing) in enumerate(match.drawings) {
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
			if let rect = rectForPlayer(player) {
				let location = touches.anyObject().locationInView(self)
				if rect.contains(location) {
					_controllers[player].touchBegan(location)
					_tracking = true
				}
			}
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

	private func rectForPlayer( index:Int ) -> CGRect? {

		if match == nil {
			return nil
		}

		let firstDrawing = match!.drawings.first!
		let firstRect = CGRect(x: 0, y: 0, width: firstDrawing.size.width, height: firstDrawing.size.height)
		return CGRectApplyAffineTransform(firstRect, match!.transforms[index])
	}

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