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
	private var _lastDrawnStrokeIndex:Int
	private var _cachedImage:UIImage?
	private var _renderQueue = dispatch_queue_create("com.zakariya.squizit.drawingQueue", nil)

	init(width:Int, height:Int) {
		_width = width
		_height = height
		_lastDrawnStrokeIndex = -1
		backgroundColor = UIColor.whiteColor()
	}

	var backgroundColor:UIColor {
		didSet {
			invalidate()
		}
	}

	// add stroke to drawing, return # of strokes in drawing
	func addStroke( stroke:Stroke ) -> Int {
		_strokes.append(stroke)
		return _strokes.count
	}

	// remove last stroke added to drawing
	func popStroke() {
		_strokes.removeLast()
		invalidate()
	}

	// remove all strokes starting at `mark to end
	func popStrokesTo( var mark:Int ) {
		mark = min( max(mark,0), _strokes.count )
		if mark > 0 {
			_strokes = Array<Stroke>(_strokes[0..<mark])
		} else {
			_strokes = []
		}

		invalidate()
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
		backgroundColor.set()
		UIRectFillUsingBlendMode(CGRect(x: 0, y: 0, width: _width, height: _height), kCGBlendModeNormal)

		if _debugRender {
			seedRandomColorGenerator()
		}

		for i in 0 ..< _strokes.count {
			renderStroke(_strokes[i])
		}
	}

	func render() -> UIImage {

		// Early exit if cached image is up to date
		if _cachedImage != nil && _lastDrawnStrokeIndex == _strokes.count - 1 {
			return _cachedImage!
		}

		UIGraphicsBeginImageContextWithOptions(CGSize(width: _width, height: _height), true, 0)

		if _cachedImage == nil {
			backgroundColor.set()
			UIRectFillUsingBlendMode(CGRect(x: 0, y: 0, width: _width, height: _height), kCGBlendModeNormal)
		}

		// redraw last cached image back into this context
		if let img = _cachedImage {
			img.drawAtPoint(CGPointZero)
		}

		if _debugRender {
			seedRandomColorGenerator()
		}

		//	render from _cachedImageStrokeIndex to end of _strokes
		for i in _lastDrawnStrokeIndex + 1 ..< _strokes.count {
			renderStroke(_strokes[i])
		}

		//	We're done
		_lastDrawnStrokeIndex = _strokes.count - 1
		_cachedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return _cachedImage!
	}

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
		_lastDrawnStrokeIndex = -1
	}

	private func seedRandomColorGenerator() {
		srand48(12345)

		// iterate rand sequence to meet where we would be at this point
		if _lastDrawnStrokeIndex > 0 {
			for i in 0 ... _lastDrawnStrokeIndex {
				drand48()
				drand48()
				drand48()
			}
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

		return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
	}

	private func renderStroke( stroke:Stroke ) {

		if stroke.spars.isEmpty {
			return
		}

		if !_debugRender {
			stroke.fill.set( self.backgroundColor )
		} else {
			nextRandomColor(stroke.fill).set()
		}

		var rects = UIBezierPath()

		var spar = stroke.spars[0]
		for i in 1 ..< stroke.spars.count {

			let nextSpar = stroke.spars[i]
			let interpolator1 = ControlPointCubicBezierInterpolator(a: spar.a, b: nextSpar.a )
			let interpolator2 = ControlPointCubicBezierInterpolator(a: spar.b, b: nextSpar.b )
			let subdivisions = interpolator1.recommendedSubdivisions()

			if subdivisions > 1 {

				var p0 = interpolator1.a.position
				var p1 = interpolator2.a.position

				for s in 1 ... subdivisions {

					let T = CGFloat(s) / CGFloat(subdivisions)
					let p2 = interpolator2.bezierPoint(T)
					let p3 = interpolator1.bezierPoint(T)

					let rect = UIBezierPath()
					rect.moveToPoint(p0)
					rect.addLineToPoint(p1)
					rect.addLineToPoint(p2)
					rect.addLineToPoint(p3)
					rect.closePath()

					rects.appendPath(rect)
					p1 = p2;
					p0 = p3;
				}
			}

			spar = nextSpar
		}

		rects.fill()

		if _debugRender {
			rects.stroke()

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
		putColor(drawing.backgroundColor)

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

			if let color = getColor() {
				drawing?.backgroundColor = color
			}

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
