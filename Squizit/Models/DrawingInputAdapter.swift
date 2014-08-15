//
//  DrawingInputAdapter.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/15/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class DrawingInputAdapter {

	private var _points = [CGPoint](count: 5, repeatedValue: CGPoint())
	private var _pointsTop = 0
	private var _isFirstPoint = false
	private var _lastSegment = LineSegment()
	private var _undoStrokeIndexes:[Int] = []


	// MARK: Public Ivars

	var drawing:Drawing? {
		didSet {
			view?.setNeedsDisplay()
		}
	}

	private var inverseTransform:CGAffineTransform = CGAffineTransformIdentity

	var transform:CGAffineTransform = CGAffineTransformIdentity {
		didSet {
			inverseTransform = CGAffineTransformInvert(transform)
			view?.setNeedsDisplay()
		}
	}

	weak var view:UIView? {
		didSet {
			view?.setNeedsDisplay()
		}
	}

	var fill:Fill = Fill.Pencil;

	// MARK: Public API

	init(){}

	func draw() {
		assert(view != nil, "Expect non-nil view")

		if let drawing = self.drawing {
			let ctx = UIGraphicsGetCurrentContext()
			assert(ctx != nil, "Expect to be called in a view's drawRect()")

			CGContextSaveGState(ctx)
			CGContextConcatCTM(ctx, transform)

			let image = drawing.render()
			image.drawAtPoint(CGPoint(x: 0, y: 0), blendMode: kCGBlendModeMultiply, alpha: 1)

			CGContextRestoreGState(ctx)
		}
	}

	func touchBegan( locationInView:CGPoint ) {
		if let drawing = self.drawing {
			let locationInDrawing:CGPoint = CGPointApplyAffineTransform( locationInView, inverseTransform )

			_pointsTop = 0
			_points[_pointsTop] = locationInDrawing
			_isFirstPoint = true

			_undoStrokeIndexes.append(drawing.strokes.count)
		}
	}

	func touchMoved( locationInView:CGPoint ) {
		if let drawing = self.drawing {
			let locationInDrawing:CGPoint = CGPointApplyAffineTransform( locationInView, inverseTransform )

			_points[++_pointsTop] = locationInDrawing;

			if _pointsTop == 4 {

				renderStroke()

				drawing.render { [unowned self]	(image) -> () in
					print(".") // adding this line seems to work around a compiler bug!?
					self.view?.setNeedsDisplay()
				}
			}
		}
	}

	func touchEnded() {
		view?.setNeedsDisplay()
	}

	func undo() {
		if let drawing = self.drawing {
			if !_undoStrokeIndexes.isEmpty {
				let mark = _undoStrokeIndexes.removeLast()
				drawing.popStrokesTo(mark)
				view?.setNeedsDisplay()
			}
		}
	}

	// MARK: Private API

	private func renderStroke() {

		_points[3] = CGPoint(x: (_points[2].x + _points[4].x)/2, y: (_points[2].y + _points[4].y)/2)

		var pointsBuffer:[CGPoint] = []
		for i in 0 ..< 4 {
			pointsBuffer.append(_points[i]);
		}

		_points[0] = _points[3]
		_points[1] = _points[4]
		_pointsTop = 1

		var stroke = Stroke( fill: self.fill )
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

			stroke.spars.append( Stroke.Spar(a: a, b: b))
			stroke.spars.append( Stroke.Spar(a: c, b: d))

			_lastSegment = ls[3]
		}

		drawing!.addStroke(stroke)
	}

}