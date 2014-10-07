//
//  Drawing.swift
//  FreehandSwift
//
//  Created by Shamyl Zakariya on 8/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

let DrawingSerializationCookie:[UInt8] = [73, 71, 64, 72]
let DrawingSerializationVersion_V0:Int32 = 0


class Drawing {

	private var _debugRender = false
	private var _strokes:[Stroke] = []
	private var _boundingRect = CGRect.nullRect

	init() {}

	func addStroke( stroke:Stroke ) {
		_strokes.append(stroke)
		_lastDrawnStrokeChunkIndex = -1
	}

	// remove last stroke added to drawing, returning bounding rect of removed stroke, if one was removed
	func popStroke() -> CGRect? {
		if !_strokes.isEmpty {

			let last = _strokes.last!
			let bounds = last.boundingRect

			_strokes.removeLast()
			invalidate()
			updateBoundingRect()

			return bounds
		}

		return nil
	}

	func updateBoundingRect() {
		if !_strokes.isEmpty {

			//	if the current _boundingRect is null, we need to get the union rect of all strokes,
			//	otherwise, just the newest added stroke. This is because popStroke() nulls the _boundingRect

			if _boundingRect.isNull {

				for stroke in _strokes {
					_boundingRect.union(stroke.boundingRect)
				}

			} else {
				_boundingRect.union(_strokes[_strokes.count-1].boundingRect)
			}
		} else {
			_boundingRect = CGRect.nullRect
		}
	}

	var boundingRect:CGRect {
		return _boundingRect
	}

	func clear() {
		_strokes = []
		invalidate()
	}

	var strokes:[Stroke] {
		return _strokes
	}

	var debugRender:Bool {
		get { return _debugRender }
		set(d) {
			_debugRender = d
			invalidate()
		}
	}

	func draw() {
		if _debugRender {
			seedRandomColorGenerator()
		}

		let ctx = UIGraphicsGetCurrentContext()
		for stroke in _strokes {
			renderStroke(ctx, stroke: stroke, chunkIndex: 0)
		}
	}


	private var _lastDrawnStrokeChunkIndex:Int = -1
	private var _cachedImage:UIImage?
	private var _cachedImageViewport:CGRect?

	/**
		synchronously renders the drawing, returning a tuple containing the rendered result image, and a 
		dirtyRect describing the updated region of the image from the last time render was called.
		
		If the image is unchanged from the last time render() was called, dirtyRect will be CGRect.nullRect
	*/
	func render( viewport:CGRect ) -> (image:UIImage,dirtyRect:CGRect) {

		if let cachedImageViewport = _cachedImageViewport {
			if let currentStroke = _strokes.last {
				if _cachedImage != nil && _lastDrawnStrokeChunkIndex == currentStroke.chunks.count - 1 && cachedImageViewport == viewport {
					return (image:_cachedImage!, dirtyRect:CGRect.nullRect)
				}
			}

			// if we're here we have a cached image viewport but it != the requested one: invalidate
			if cachedImageViewport != viewport {
				invalidate()
			}
		} else {
			// if we're here we don't have a cached image viewport so we need to invalidate
			invalidate()
		}


		if _debugRender {
			seedRandomColorGenerator()
		}

		UIGraphicsBeginImageContextWithOptions(CGSize(width: viewport.width, height: viewport.height), true, 0)
		let ctx = UIGraphicsGetCurrentContext()

		if _cachedImage == nil {
			UIColor.whiteColor().set()
			UIRectFillUsingBlendMode(CGRect(x: 0, y: 0, width: viewport.width, height: viewport.height), kCGBlendModeNormal)

			// render all strokes up to but not including the last stroke
			if _strokes.count > 1 {
				for i in 0 ..< _strokes.count - 1 {
					renderStroke(ctx, stroke: _strokes[i], chunkIndex: 0)
				}
			}
		}

		// redraw last cached image back into this context
		if let cachedImage = _cachedImage {
			cachedImage.drawAtPoint(CGPointZero)
		}

		// draw the undrawn chunks of the current stroke
		var dirtyRect:CGRect = CGRect.nullRect

		if let stroke = _strokes.last {
			stroke.fill.set()
			dirtyRect = renderStroke(ctx, stroke: stroke, chunkIndex: _lastDrawnStrokeChunkIndex + 1 )
			_lastDrawnStrokeChunkIndex = stroke.chunks.count - 1
		}

		_cachedImage = UIGraphicsGetImageFromCurrentImageContext()
		_cachedImageViewport = viewport
		UIGraphicsEndImageContext()

		return (image:_cachedImage!, dirtyRect: dirtyRect)
	}

	private var _renderQueue = dispatch_queue_create("com.zakariya.squizit.drawingQueue", nil)

	/**
		Render on background queue, calling `done on main queue when complete, passing the rendered image
	*/
	func render( viewport:CGRect, done: ((image:UIImage, dirtyRect:CGRect )->Void)? ) {
		dispatch_async( _renderQueue ) {
			let result = self.render( viewport );
			if let d = done {
				dispatch_async( dispatch_get_main_queue()) {
					d( image: result.image, dirtyRect: result.dirtyRect )
				}
			}
		}
	}

	// MARK: Privates

	private func invalidate() {
		_cachedImage = nil
		_lastDrawnStrokeChunkIndex = -1
		_boundingRect = CGRect.nullRect
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

	/**
		returns the rect containing all chunks in the rendered stroke
	*/
	private func renderStroke( context:CGContext, stroke:Stroke, chunkIndex:Int ) -> CGRect {


		if stroke.chunks.isEmpty {
			return CGRect.nullRect
		}

		if !_debugRender {
			stroke.fill.set()
		} else {
			nextRandomColor(stroke.fill).set()
		}

		var dirtyRect = CGRect.nullRect

		for i in chunkIndex ..< stroke.chunks.count {
			let chunk = stroke.chunks[i]

			var chunkPath = UIBezierPath()
			chunkPath.moveToPoint( chunk.start.a.position )
			chunkPath.addCurveToPoint(chunk.end.a.position, controlPoint1: chunk.start.a.control, controlPoint2: chunk.end.a.control)
			chunkPath.addLineToPoint(chunk.end.b.position)
			chunkPath.addCurveToPoint(chunk.start.b.position, controlPoint1: chunk.end.b.control, controlPoint2: chunk.start.b.control)
			chunkPath.closePath()
			chunkPath.fill()

			// expand dirtyRect to contain chunk
			dirtyRect = dirtyRect.rectByUnion(chunkPath.bounds)

			if _debugRender {
				UIColor.blackColor().set()
				chunkPath.stroke()

				var spars = UIBezierPath()
				var handles = UIBezierPath()

				for spar in [chunk.start, chunk.end] {

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

		return dirtyRect
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
			drawing = Drawing()

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
