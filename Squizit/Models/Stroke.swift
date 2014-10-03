//
//  Stroke.swift
//  FreehandSwift
//
//  Created by Shamyl Zakariya on 8/5/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

enum Fill {

	case Pencil
	case Brush
	case Eraser

	func set() {
		switch self {
			case .Pencil, .Brush:
				UIColor.blackColor().set()

			case .Eraser:
				UIColor.whiteColor().colorWithAlphaComponent(0.8).set()
		}
	}

	var size:(CGFloat,CGFloat) {
		get {
			switch self {
				case .Pencil:
					return (0.5,4.0)

				case .Brush:
					return (1.0,16.0)

				case .Eraser:
					return (20.0,20.0)
			}
		}
	}
}


struct ControlPoint:Printable,Equatable {
	let position:CGPoint
	let control:CGPoint

	init( position:CGPoint, control:CGPoint ) {
		self.position = position
		self.control = control
	}

	var description:String {
		return "ControlPoint p:(\(position.x),\(position.y)) c:(\(control.x),\(control.y))"
	}
}


class Stroke : Equatable {

	struct Chunk : Equatable {

		struct Spar:Equatable {
			let a:ControlPoint
			let b:ControlPoint

			init(a:ControlPoint, b:ControlPoint){
				self.a = a
				self.b = b
			}
		}

		let start:Spar
		let end:Spar

		var boundingRect:CGRect {
			return CGRect.rectByFitting(
				start.a.position, start.a.control, end.a.control, end.a.position, // contains 'a'-side bezier curve
				start.b.position, start.b.control, end.b.control, end.b.position // contains 'b'-side bezier curve
			)
		}
	}

	var fill:Fill = Fill.Pencil
	var chunks:[Chunk] = []

	init( fill:Fill ) {
		self.fill = fill
	}

	var boundingRect:CGRect {
		return chunks.reduce(CGRect.nullRect, combine: { (bounds:CGRect, chunk:Stroke.Chunk) -> CGRect in
			return bounds.rectByUnion(chunk.boundingRect)
		})
	}
}

// MARK: Equatable

func == (left:ControlPoint, right:ControlPoint) -> Bool {
	return CGPointEqualToPoint( left.position, right.position ) &&
		CGPointEqualToPoint(left.control, right.control)
}

func == (left:Stroke.Chunk.Spar, right:Stroke.Chunk.Spar) -> Bool {
	return left.a == right.a && left.b == right.b
}

func == (left:Stroke.Chunk, right:Stroke.Chunk) -> Bool {

	return left.start == right.start && left.end == right.end
}

func == (left:Stroke, right:Stroke) -> Bool {
	if left.fill != right.fill {
		return false
	}

	if left.chunks.count != right.chunks.count {
		return false
	}

	for (i,chunk) in enumerate(left.chunks) {
		if chunk != right.chunks[i] {
			return false
		}
	}

	return true
}

extension ByteBuffer {

	public class func requiredSizeForFill() -> Int {
		return sizeof(UInt8)
	}

	func putFill( fill:Fill ) -> Bool {
		if remaining >= ByteBuffer.requiredSizeForFill() {
			switch fill {
				case .Pencil:
					putUInt8(0)

				case .Brush:
					putUInt8(1)

				case .Eraser:
					putUInt8(2)
			}
			return true
		}

		return false
	}

	func getFill() -> Fill {
		switch( getUInt8() ) {
			case 0: return .Pencil
			case 1: return .Brush
			case 2: return .Eraser
			default: return .Pencil
		}
	}

	class func requiredSizeForControlPoint() -> Int {
		return 4*sizeof(Float64)
	}

	func putControlPoint( cp:ControlPoint ) -> Bool {
		if remaining >= ByteBuffer.requiredSizeForControlPoint() {
			putFloat64(Float64(cp.position.x))
			putFloat64(Float64(cp.position.y))
			putFloat64(Float64(cp.control.x))
			putFloat64(Float64(cp.control.y))
			return true
		}

		return false
	}

	func getControlPoint() -> ControlPoint {
		return ControlPoint(
			position: CGPoint( x:CGFloat(getFloat64()), y: CGFloat(getFloat64()) ),
			control: CGPoint( x:CGFloat(getFloat64()), y: CGFloat(getFloat64()) ))
	}

	class func requiredSizeForStrokeChunk( chunk:Stroke.Chunk ) -> Int {
		return 4 * requiredSizeForControlPoint()
	}

	func putStrokeChunk( chunk:Stroke.Chunk ) -> Bool {
		if remaining < ByteBuffer.requiredSizeForStrokeChunk( chunk ) {
			return false
		}

		putControlPoint(chunk.start.a)
		putControlPoint(chunk.start.b)
		putControlPoint(chunk.end.a)
		putControlPoint(chunk.end.b)

		return true
	}

	func getStrokeChunk() -> Stroke.Chunk {
		return Stroke.Chunk(
			start: Stroke.Chunk.Spar( a: getControlPoint(), b: getControlPoint() ),
			end: Stroke.Chunk.Spar( a: getControlPoint(), b: getControlPoint() )
		)
	}

	class func requiredSizeForStroke( stroke:Stroke ) -> Int {
		return requiredSizeForFill() +
			sizeof(Int32) + // number of chunks
			stroke.chunks.reduce(0, combine: { (total:Int, chunk:Stroke.Chunk) -> Int in
				return total + ByteBuffer.requiredSizeForStrokeChunk( chunk )
			})
	}

	func putStroke( stroke:Stroke ) -> Bool {

		if !putFill(stroke.fill) {
			return false
		}

		if remaining < sizeof(Int32) {
			return false
		}

		putInt32(Int32(stroke.chunks.count))

		for chunk in stroke.chunks {
			if !putStrokeChunk(chunk) {
				return false
			}
		}

		return true
	}

	func getStroke() -> Stroke {
		var stroke = Stroke( fill: getFill() )
		let count = getInt32()
		for i in 0 ..< count {
			stroke.chunks.append( getStrokeChunk() )
		}

		return stroke
	}

	class func requiredSizeForCGRect() -> Int {
		return 4 * sizeof(Float64)
	}

	func putCGRect( t:CGRect ) -> Bool {
		if remaining < ByteBuffer.requiredSizeForCGRect() {
			return false
		}

		putFloat64( Float64(t.origin.x))
		putFloat64( Float64(t.origin.y))
		putFloat64( Float64(t.size.width))
		putFloat64( Float64(t.size.height))

		return true
	}

	func getCGRect() -> CGRect? {
		if remaining < ByteBuffer.requiredSizeForCGRect() {
			return nil
		}

		return CGRect(x: CGFloat(getFloat64()), y: CGFloat(getFloat64()), width: CGFloat(getFloat64()), height: CGFloat(getFloat64()))
	}

	class func requiredSizeForCGAffineTransform() -> Int {
		return 6 * sizeof(Float64)
	}

	func putCGAffineTransform( t:CGAffineTransform ) -> Bool {
		if remaining < ByteBuffer.requiredSizeForCGAffineTransform() {
			return false
		}

		putFloat64( Float64(t.a))
		putFloat64( Float64(t.b))
		putFloat64( Float64(t.c))
		putFloat64( Float64(t.d))
		putFloat64( Float64(t.tx))
		putFloat64( Float64(t.ty))

		return true
	}

	func getCGAffineTransform() -> CGAffineTransform? {
		if remaining < ByteBuffer.requiredSizeForCGAffineTransform() {
			return nil
		}

		return CGAffineTransformMake(
			CGFloat(getFloat64()),
			CGFloat(getFloat64()),
			CGFloat(getFloat64()),
			CGFloat(getFloat64()),
			CGFloat(getFloat64()),
			CGFloat(getFloat64()))
	}

}

struct ControlPointCubicBezierInterpolator {

	let a:ControlPoint
	let	b:ControlPoint

	init( a:ControlPoint, b:ControlPoint ) {
		self.a = a
		self.b = b
	}

	func bezierPoint( t: CGFloat ) -> CGPoint {
		// from http://ciechanowski.me/blog/2014/02/18/drawing-bezier-curves/

		let Nt = 1.0 - t
		let A = Nt * Nt * Nt
		let B = 3.0 * Nt * Nt * t
		let C = 3.0 * Nt * t * t
		let D = t * t * t

		var p = a.position.scale(A)
		p = p.add( a.control.scale(B) )
		p = p.add( b.control.scale(C) )
		p = p.add( b.position.scale(D) )

		return p
	}

	func recommendedSubdivisions() -> Int {
		// from http://ciechanowski.me/blog/2014/02/18/drawing-bezier-curves/

		let L0 = a.position.distance(a.control)
		let L1 = a.control.distance(b.control)
		let L2 = b.control.distance(b.position)
		let ApproximateLength = L0 + L1 + L2

		let Min:CGFloat = 10.0
		let Segs:CGFloat = ApproximateLength / 30.0
		let Slope:CGFloat = 0.6

		return Int(ceil(sqrt( (Segs*Segs) * Slope + (Min*Min))))
	}
}