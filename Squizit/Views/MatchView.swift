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

	private var _adapters:[DrawingInputAdapter] = []
	private var _trackingIndex:Int?

	required init(coder aDecoder: NSCoder!) {
		super.init( coder: aDecoder )
	}

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

		_trackingIndex = nil
		if let touch = touches.anyObject() as? UITouch {
			let location = touch.locationInView(self)
			if let idx = drawingIndexForPoint(location) {
				_trackingIndex = idx
				_adapters[_trackingIndex!].touchBegan(location)
			}
		}
	}

	override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {

		if let trackingIndex = _trackingIndex {
			if let touch = touches.anyObject() as? UITouch {
				_adapters[_trackingIndex!].touchMoved(touch.locationInView(self))
			}
		}
	}

	override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {

		if let trackingIndex = _trackingIndex {
			_adapters[_trackingIndex!].touchEnded()
		}

		_trackingIndex = nil
	}

	override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
		touchesEnded(touches, withEvent: event)
	}


	// MARK: Private

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
				let adapter = DrawingInputAdapter()
				adapter.drawing = drawing
				adapter.view = self
				adapter.transform = match.transforms[i]

				_adapters.append(adapter)
			}
		}
	}
}