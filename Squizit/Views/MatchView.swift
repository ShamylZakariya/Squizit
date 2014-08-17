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

	private var _adapters:[DrawingInputController] = []
	private var _tracking:Bool = false

	var adapters:[DrawingInputController] { return _adapters }

	required init(coder aDecoder: NSCoder!) {
		super.init( coder: aDecoder )
	}

	// MARK: Public API

	func undo() {
		if let player = self.player {
			_adapters[player].undo()
		}
	}

	// MARK: UIView Overrides

	override func drawRect(rect: CGRect) {
		let ctx = UIGraphicsGetCurrentContext()
		if let match = self.match {
			for (i,drawing) in enumerate(match.drawings) {
				let transform = match.transforms[i]
				_adapters[i].draw(ctx)
			}
		}
	}

	override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {

		if touches.count > 1 {
			return
		}


		self.player = drawingIndexForPoint(touches.anyObject().locationInView(self))

		if let player = self.player {
			if let rect = rectForPlayer(player) {
				let location = touches.anyObject().locationInView(self)
				if rect.contains(location) {
					_adapters[player].touchBegan(location)
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
		_adapters[player!].touchMoved(location)
	}

	override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {

		if !_tracking {
			return
		}

		_adapters[player!].touchEnded()
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

	private func drawingIndexForPoint( point:CGPoint ) -> Int? {
		if let match = self.match {
			if let firstDrawing = match.drawings.first {
				let rect = CGRect(x: 0, y: 0, width: firstDrawing.size.width, height: firstDrawing.size.height)
				for (i,transform) in enumerate(match.transforms) {
					let transformedRect = CGRectApplyAffineTransform(rect, transform)
					if transformedRect.contains(point) {
						return i
					}
				}
			}
		}

		return nil
	}

	private func configure(){
		_adapters = []
		if let match = self.match {
			for (i,drawing) in enumerate(match.drawings) {
				let adapter = DrawingInputController()
				adapter.drawing = drawing
				adapter.view = self
				adapter.transform = match.transforms[i]

				_adapters.append(adapter)
			}
		}
	}
}