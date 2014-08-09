//
//  Drawing.swift
//  FreehandSwift
//
//  Created by Shamyl Zakariya on 8/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit



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

	func strokes() ->[Stroke] {
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

	func render(done maybeDone: ((image:UIImage) -> ())?) {
		dispatch_async( _renderQueue ) {
			let image = self.render();
			if let done = maybeDone {
				dispatch_async( dispatch_get_main_queue()) {
					done( image:image )
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
			case Fill.Pencil:
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
			stroke.fill.set()
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
			} else {
//				let rect = UIBezierPath()
//				rect.moveToPoint(spar.a.position)
//				rect.addLineToPoint(spar.b.position)
//				rect.addLineToPoint(nextSpar.b.position)
//				rect.addLineToPoint(nextSpar.a.position)
//				rect.closePath()
//				rects.appendPath(rect)
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
