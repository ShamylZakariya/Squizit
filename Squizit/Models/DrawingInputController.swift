//
//  DrawingInputController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/15/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class DrawingInputController {

	private var _points = [CGPoint](count: 5, repeatedValue: CGPoint.zeroPoint)
	private var _pointsTop = 0
	private var _isFirstPoint = false
	private var _lastSegment = LineSegment()

	// MARK: Public Ivars

	var drawing:Drawing? {
		didSet {
			view?.setNeedsDisplay()
		}
	}

	// the viewport into the drawing - this is what will be rendered on screen
	var viewport:CGRect = CGRect.zeroRect {
		didSet {
			view?.setNeedsDisplay()
		}
	}

	weak var view:UIView? {
		didSet {
			view?.setNeedsDisplay()
		}
	}

	var fill:Fill = Fill.Pencil;

	// MARK: Public

	init(){}

	func undo() {
		if let drawing = drawing {
			if let dirtyRect = drawing.popStroke() {
				self.view?.setNeedsDisplayInRect( drawingToScreen(dirtyRect) )
			} else {
				view?.setNeedsDisplay()
			}
		}
	}

	func drawUsingImmediatePipeline( dirtyRect:CGRect, context:CGContextRef) {
		if let drawing = drawing {
			drawing.draw(dirtyRect, context: context)
		}
	}

	func drawUsingBitmapPipeline( context:CGContextRef ) {
		if let drawing = drawing {
			let image = drawing.render( viewport ).image
			image.drawAtPoint( viewport.origin, blendMode: kCGBlendModeMultiply, alpha: 1)
		}
	}

	func touchBegan( locationInView:CGPoint ) {
		if let drawing = drawing {
			let locationInDrawing = screenToDrawing( locationInView )

			_pointsTop = 0
			_points[_pointsTop] = locationInDrawing
			_isFirstPoint = true

			_activeStroke = Stroke( fill: self.fill )
			drawing.addStroke(_activeStroke!)
		}
	}

	func touchMoved( locationInView:CGPoint ) {
		if let drawing = drawing {
			let locationInDrawing = screenToDrawing( locationInView )

			_points[++_pointsTop] = locationInDrawing;

			if _pointsTop == 4 {

				appendToStroke()

				drawing.render( viewport ) {
					[unowned self]
					(image:UIImage, dirtyRect:CGRect ) in
					if !dirtyRect.isNull {

						self.view?.setNeedsDisplayInRect( self.drawingToScreen(dirtyRect) )

					} else {
						self.view?.setNeedsDisplay()
					}
					return
				}
			}
		}
	}

	func touchEnded() {
		if let drawing = drawing {
			drawing.updateBoundingRect()
		}

		_activeStroke = nil
		view?.setNeedsDisplay()
	}

	// MARK: Private

	private func screenToDrawing( location:CGPoint ) -> CGPoint {
		return location
	}

	private func drawingToScreen( rect:CGRect ) -> CGRect {
		return rect
	}

	private var _activeStroke:Stroke?
	private func appendToStroke() {

		_points[3] = CGPoint(x: (_points[2].x + _points[4].x)/2, y: (_points[2].y + _points[4].y)/2)

		var pointsBuffer:[CGPoint] = []
		for i in 0 ..< 4 {
			pointsBuffer.append(_points[i]);
		}

		_points[0] = _points[3]
		_points[1] = _points[4]
		_pointsTop = 1

		let fillSize = self.fill.size

		let SCALE:CGFloat = 1.0
		let RANGE:CGFloat = 100
		let MIN:CGFloat = fillSize.0
		let MAX:CGFloat = fillSize.1

		var ls = [LineSegment](count:4,repeatedValue:LineSegment())
		for var i = 0; i < pointsBuffer.count; i+=4 {

			if ( _isFirstPoint ) {
				ls[0] = LineSegment(firstPoint: pointsBuffer[0], secondPoint: pointsBuffer[0])
				_isFirstPoint = false
			}
			else {
				ls[0] = _lastSegment
			}

			//
			//	Dropping distanceSquared is the key - use distance and I can return to the tuple-based min/max sizing
			//	and I'll no longer have the weird lumpy shapes which are resultant of the squaring curve
			//

			let frac1 = SCALE * (MIN + (clamp( distance(pointsBuffer[i+0], pointsBuffer[i+1]), 0.0, RANGE )/RANGE) * (MAX-MIN))
			let frac2 = SCALE * (MIN + (clamp( distance(pointsBuffer[i+1], pointsBuffer[i+2]), 0.0, RANGE )/RANGE) * (MAX-MIN))
			let frac3 = SCALE * (MIN + (clamp( distance(pointsBuffer[i+2], pointsBuffer[i+3]), 0.0, RANGE )/RANGE) * (MAX-MIN))

			ls[1] = LineSegment(firstPoint: pointsBuffer[i+0], secondPoint: pointsBuffer[i+1]).perpendicular(absoluteLength: frac1)
			ls[2] = LineSegment(firstPoint: pointsBuffer[i+1], secondPoint: pointsBuffer[i+2]).perpendicular(absoluteLength: frac2)
			ls[3] = LineSegment(firstPoint: pointsBuffer[i+2], secondPoint: pointsBuffer[i+3]).perpendicular(absoluteLength: frac3)

			let a = ControlPoint(position: ls[0].firstPoint, control: ls[1].firstPoint)
			let b = ControlPoint(position: ls[0].secondPoint, control: ls[1].secondPoint)

			let c = ControlPoint(position: ls[3].firstPoint, control: ls[2].firstPoint)
			let d = ControlPoint(position: ls[3].secondPoint, control: ls[2].secondPoint)

			let chunk = Stroke.Chunk(
				start: Stroke.Chunk.Spar(a: a, b: b),
				end: Stroke.Chunk.Spar(a: c, b: d)
			)

			_activeStroke!.chunks.append(chunk)

			_lastSegment = ls[3]
		}
	}
}

// MARK: -

/**
	Adapter to simplify forwarding UIView touch events to a DrawingInputController
*/
extension DrawingInputController {

	func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent, offset:CGPoint = CGPoint.zeroPoint) {

		if touches.count > 1 {
			return
		}

		let touch = touches.first as! UITouch
		let location = touch.locationInView(view!)
		touchBegan(location.subtract(offset))
	}

	func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent, offset:CGPoint = CGPoint.zeroPoint) {

		if touches.count > 1 {
			return
		}

		let touch = touches.first as! UITouch
		let location = touch.locationInView(view!)
		touchMoved(location.subtract(offset))
	}

	func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
		touchEnded()
	}

	func touchesCancelled(touches: Set<NSObject>, withEvent event: UIEvent) {
		touchEnded()
	}
}