//
//  DrawingView.swift
//  FreehandSwift
//
//  Created by Shamyl Zakariya on 8/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class DrawingView: UIView {

	private var _pts = [CGPoint](count: 5, repeatedValue: CGPoint())
	private var _ctr = 0
	private var _isFirstTouchPoint = false
	private var _lastSegmentOfPrev = LineSegment()
	private var _undoPoints:[Int] = []
	private var _tracking:Bool = false

	required init(coder aDecoder: NSCoder!) {
		self.drawing = Drawing(width: 1024, height: 1024)
		self.fill = Fill.Pencil

		super.init( coder: aDecoder )

		backgroundColor = UIColor(red: 1, green: 0.98, blue: 0.95, alpha: 1)
		contentMode = .Redraw
	}

	var drawing:Drawing {
		didSet {
			setNeedsDisplay()
		}
	}

	var fill:Fill;

	override func drawRect(rect: CGRect) {
		// draw centered in view
		let size = drawing.size
		let viewCenter = CGPointMake( self.bounds.size.width/2, self.bounds.size.height / 2 )
		let topLeftCorner = CGPointMake( floor(viewCenter.x - size.width/2), floor(viewCenter.y - size.height/2) )

		let image = drawing.render()
		image.drawAtPoint(topLeftCorner, blendMode: kCGBlendModeMultiply, alpha: 1)
	}

	// MARK: Touch

	override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {

		if touches.count > 1 {
			return
		}

		if let touch = touches.anyObject() as? UITouch {

			_tracking = true
			_ctr = 0
			_pts[0] = viewToDrawing(touch.locationInView(self))
			_isFirstTouchPoint = true

			_undoPoints.append(drawing.strokes.count)
		}
	}

	override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {

		if !_tracking {
			return
		}

		if let touch = touches.anyObject() as? UITouch {
			let p = viewToDrawing(touch.locationInView(self))

			_ctr++;
			_pts[_ctr] = p;

			if _ctr == 4 {

				renderStroke()

				drawing.render {
					(image) -> () in
					self.setNeedsDisplay()
				}
			}
		}
	}

	override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
		_tracking = false
		setNeedsDisplay();
	}

	override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
		touchesEnded(touches, withEvent: event)
	}

	func undo() {
		if !_undoPoints.isEmpty {
			let mark = _undoPoints.removeLast()
			drawing.popStrokesTo(mark)
			setNeedsDisplay()
		}
	}

	// MARK: Privates

	private func renderStroke() {

		_pts[3] = CGPoint(x: (_pts[2].x + _pts[4].x)/2, y: (_pts[2].y + _pts[4].y)/2)

		var pointsBuffer:[CGPoint] = []
		for i in 0 ..< 4 {
			pointsBuffer.append(_pts[i]);
		}

		_pts[0] = _pts[3]
		_pts[1] = _pts[4]
		_ctr = 1

		var stroke = Stroke( fill: self.fill )
		let fillSize = self.fill.size

		let SCALE:CGFloat = 1.0
		let RANGE:CGFloat = 100
		let MIN:CGFloat = fillSize.0
		let MAX:CGFloat = fillSize.1

		var ls = [LineSegment](count:4,repeatedValue:LineSegment())
		for var i = 0; i < pointsBuffer.count; i+=4 {

			if ( _isFirstTouchPoint ) {
				ls[0] = LineSegment(firstPoint: pointsBuffer[0], secondPoint: pointsBuffer[0])
				_isFirstTouchPoint = false
			}
			else {
				ls[0] = _lastSegmentOfPrev
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

			_lastSegmentOfPrev = ls[3]
		}

		drawing.addStroke(stroke)
	}

	// convert coordinate from view to drawing coordinate system
	private func viewToDrawing( p:CGPoint ) -> CGPoint {
		let size = drawing.size
		let viewCenter = CGPointMake( self.bounds.size.width/2, self.bounds.size.height / 2 )
		let topLeftCorner = CGPointMake( floor(viewCenter.x - size.width/2), floor(viewCenter.y - size.height/2) )
		return p.subtract(topLeftCorner)
	}

}
