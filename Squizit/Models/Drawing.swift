//
//  Drawing.swift
//  FreehandSwift
//
//  Created by Shamyl Zakariya on 8/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit
import Lilliput

let DrawingSerializationCookie:[UInt8] = [73, 71, 64, 72]
let DrawingSerializationVersion_V0:Int32 = 0


class Drawing {

	private let _width:Int
	private let _height:Int

	private var _debugRender = false
	private var _strokes:[Stroke] = []

	init(width:Int, height:Int) {
		_width = width
		_height = height
	}

	func addStroke( stroke:Stroke ) {
		_strokes.append(stroke)
		_cachedImage = _currentImage
	}

	// remove last stroke added to drawing
	func popStroke() {
		if !_strokes.isEmpty {
			_strokes.removeLast()
			invalidate()
		}
	}

	func clear() {
		_strokes = []
		invalidate()
	}

	var strokes:[Stroke] {
		return _strokes
	}

	var image:UIImage? {
		return _cachedImage
	}

	var size:CGSize {
		return CGSize(width: _width, height: _height)
	}

	var debugRender:Bool {
		get { return _debugRender }
		set(d) {
			_debugRender = d
			invalidate()
		}
	}

	func draw() {
		let rect = CGRect(x: 0, y: 0, width: _width, height: _height)

		UIColor.whiteColor().set()
		UIRectFillUsingBlendMode(rect, kCGBlendModeNormal)

		if _debugRender {
			seedRandomColorGenerator()
		}

		let ctx = UIGraphicsGetCurrentContext()
		for stroke in _strokes {
			renderStroke(ctx, stroke: stroke)
		}
	}


	private var _lastDrawnStrokeLength:Int = -1
	private var _cachedImage:UIImage?
	private var _currentImage:UIImage?

	func render() -> UIImage {

		if let currentStroke = _strokes.last {
			if _currentImage != nil && currentStroke.spars.count == _lastDrawnStrokeLength {
				return _currentImage!
			}
		}

		/*
			we cache two images.
			_cachedImage is a cached rendering of all strokes up to but not including the last (or current) stroke
			_currentImage is _cachedImage + rendering of current stroke
			
			we always return _currentImage
			when a new stroke is started ( via addStroke ) _cachedImage is set to _currentImage
		*/


		if _debugRender {
			seedRandomColorGenerator()
		}

		UIGraphicsBeginImageContextWithOptions(CGSize(width: _width, height: _height), true, 0)
		let ctx = UIGraphicsGetCurrentContext()

		if _cachedImage == nil {
			UIColor.whiteColor().set()
			UIRectFillUsingBlendMode(CGRect(x: 0, y: 0, width: _width, height: _height), kCGBlendModeNormal)

			// render all strokes up to but not including the last stroke
			if _strokes.count > 1 {
				for i in 0 ..< _strokes.count - 1 {
					renderStroke(ctx, stroke: _strokes[i])
				}
			}
		}

		// redraw last cached image back into this context
		if let cachedImage = _cachedImage {
			CGContextSetAlpha(ctx, 1)
			cachedImage.drawAtPoint(CGPointZero)
		}

		// draw the current stroke
		if let stroke = _strokes.last {
			renderStroke(ctx, stroke: stroke)
			_lastDrawnStrokeLength = stroke.spars.count
		}

		_currentImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return _currentImage!
	}

	private var _renderQueue = dispatch_queue_create("com.zakariya.squizit.drawingQueue", nil)

	/**
		Render on background queue, calling `done on main queue when complete, passing the rendered image
	*/
	func render( done: ((image:UIImage)->Void)? ) {
		dispatch_async( _renderQueue ) {
			let image = self.render();
			if let d = done {
				dispatch_async( dispatch_get_main_queue()) {
					d( image:image )
				}
			}
		}
	}

	// MARK: Privates

	private func invalidate() {
		_cachedImage = nil
		_currentImage = nil
		_lastDrawnStrokeLength = -1
	}

	private func seedRandomColorGenerator() {
		srand48(12345)

		// each stroke is a unique color, so pump the random seed to get us to a consistent position
		for i in 0 ... _strokes.count {
			drand48()
			drand48()
			drand48()
		}
	}

	private func nextRandomColor( fill:Fill ) -> UIColor {
		var red:Double
		var green:Double
		var blue:Double

		switch fill {
			case Fill.Pencil,Fill.Brush:
				red = drand48()
				green = fract(red + drand48() * 0.5)
				blue = fract( green + drand48() * 0.5)

			case Fill.Eraser:
				red = 0.5 + 0.5 * drand48()
				green = 0.1 + 0.2 * drand48()
				blue = 0.1 + 0.2 * drand48()
		}

		return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 0.25)
	}

	private func renderStroke( context:CGContext, stroke:Stroke ) {

		if stroke.spars.isEmpty {
			return
		}

		if !_debugRender {
			stroke.fill.set()
			CGContextSetAlpha(context, 0.8)
		} else {
			nextRandomColor(stroke.fill).set()
		}

		var shapes = UIBezierPath()
		var cp:ControlPoint = stroke.spars[0].a

		shapes.moveToPoint( cp.position )
		for i in 1 ..< stroke.spars.count {
			let ncp = stroke.spars[i].a
			shapes.addCurveToPoint(ncp.position, controlPoint1: cp.control, controlPoint2: ncp.control)
			cp = ncp
		}

		cp = stroke.spars.last!.b
		shapes.addLineToPoint(cp.position)
		for var i = stroke.spars.count - 2; i >= 0; i-- {
			let ncp = stroke.spars[i].b
			shapes.addCurveToPoint(ncp.position, controlPoint1: cp.control, controlPoint2: ncp.control)
			cp = ncp
		}

		shapes.closePath()
		shapes.fill()

		if _debugRender {
			UIColor.blackColor().set()
			shapes.stroke()

			var spars = UIBezierPath()
			var handles = UIBezierPath()

			for spar in stroke.spars {

				spars.moveToPoint(spar.a.position)
				spars.addLineToPoint(spar.b.position)

				handles.moveToPoint(spar.a.position)
				handles.addLineToPoint(spar.a.control)

				handles.moveToPoint(spar.b.position)
				handles.addLineToPoint(spar.b.control)
			}

			switch stroke.fill {
				case .Pencil:
					UIColor.blackColor().setStroke()

				case .Brush:
					UIColor.greenColor().setStroke()

				case .Eraser:
					UIColor.redColor().setStroke()
			}

			let dashes:[CGFloat] = [4.0,4.0]
			spars.setLineDash(dashes, count: dashes.count, phase: 0)

			spars.stroke()

			UIColor.greenColor().set()
			handles.setLineDash(dashes, count: dashes.count, phase: 0)
			handles.stroke()
		}
	}
}



extension ByteBuffer  {

	class func requiredSizeForDrawing( drawing:Drawing ) -> Int {
		let headerSize = sizeof(UInt8)*DrawingSerializationCookie.count // #cookie
			+ 4*sizeof(Int32) // version # + width + height + #strokes
			+ ByteBuffer.requiredSpaceForColor()

		var strokeSize = 0
		for stroke in drawing.strokes {
			strokeSize += ByteBuffer.requiredSizeForStroke(stroke)
		}

		return headerSize + strokeSize
	}

	func putDrawing( drawing:Drawing ) -> Bool {
		if remaining < ByteBuffer.requiredSizeForDrawing( drawing ) {
			return false
		}

		putUInt8(DrawingSerializationCookie)
		putInt32(Int32(DrawingSerializationVersion_V0))
		putInt32(Int32(drawing.size.width))
		putInt32(Int32(drawing.size.height))

		putInt32(Int32(drawing.strokes.count))
		for stroke in drawing.strokes {
			if !putStroke(stroke) {
				return false
			}
		}

		return true;
	}

	func getDrawing() -> Result<Drawing> {
		let cookie:[UInt8] = getUInt8(4)
		let version:Int32 = getInt32()

		if cookie != DrawingSerializationCookie {
			return .Failure(Error(message: "Drawing cookie mismatch - expected: \(DrawingSerializationCookie) got: \(cookie)"))
		}

		var drawing:Drawing? = nil

		if version == DrawingSerializationVersion_V0 {
			let width = getInt32()
			let height = getInt32()

			drawing = Drawing( width: Int(width), height: Int(height) )

			let strokesCount = getInt32()
			for i in 0 ..< strokesCount {
				drawing!.addStroke( getStroke() )
			}
		} else {
			return .Failure(Error(message: "version # mismatch, unrecognized version: \(version)"))
		}

		return .Success(drawing!)
	}

}
