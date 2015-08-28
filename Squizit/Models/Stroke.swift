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

	var isEraser:Bool { return self == .Eraser }

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

// MARK: Bezier Interpolator

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

// MARK: Serialization

extension BinaryCoder {

	func getFill() -> Fill? {
		if remaining < sizeof(UInt8) {
			return nil
		}

		switch( getUInt8() ) {
			case 0: return .Pencil
			case 1: return .Brush
			case 2: return .Eraser
			default: return .Pencil
		}
	}

	func getControlPoint() -> ControlPoint? {
		if remaining < 4 * sizeof(Float64) {
			return nil
		}

		return ControlPoint(
			position: CGPoint( x:CGFloat(getFloat64()), y: CGFloat(getFloat64()) ),
			control: CGPoint( x:CGFloat(getFloat64()), y: CGFloat(getFloat64()) ))
	}

	func getStrokeChunk() -> Stroke.Chunk? {
		let sa = getControlPoint()
		let sb = getControlPoint()
		let ea = getControlPoint()
		let eb = getControlPoint()

		if sa != nil && sb != nil && ea != nil && eb != nil {
			return Stroke.Chunk(
				start: Stroke.Chunk.Spar( a: sa!, b: sb! ),
				end: Stroke.Chunk.Spar( a: ea!, b: eb! )
			)
		}

		return nil
	}

	func getStroke() -> Stroke? {
		if let fill = getFill() {
			if remaining > 0 {
				var stroke = Stroke( fill: fill )
				let count = getInt32()
				for i in 0 ..< count {
					if let chunk = getStrokeChunk() {
						stroke.chunks.append( chunk )
					} else {
						return nil
					}
				}

				return stroke
			}
		}

		return nil
	}

	func getCGRect() -> CGRect? {
		if remaining < 4 * sizeof(Float64) {
			return nil
		}

		return CGRect(x: CGFloat(getFloat64()), y: CGFloat(getFloat64()), width: CGFloat(getFloat64()), height: CGFloat(getFloat64()))
	}

	func getCGAffineTransform() -> CGAffineTransform? {
		if remaining < 6 * sizeof(Float64) {
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

extension MutableBinaryCoder {

	func putFill( fill:Fill ) {
		switch fill {
			case .Pencil:
				putUInt8(0)

			case .Brush:
				putUInt8(1)

			case .Eraser:
				putUInt8(2)
		}
	}

	func putControlPoint( cp:ControlPoint ) {
		putFloat64(Float64(cp.position.x))
		putFloat64(Float64(cp.position.y))
		putFloat64(Float64(cp.control.x))
		putFloat64(Float64(cp.control.y))
	}

	func putStrokeChunk( chunk:Stroke.Chunk ) {
		putControlPoint(chunk.start.a)
		putControlPoint(chunk.start.b)
		putControlPoint(chunk.end.a)
		putControlPoint(chunk.end.b)
	}

	func putStroke( stroke:Stroke ) {

		putFill(stroke.fill)
		putInt32(Int32(stroke.chunks.count))

		for chunk in stroke.chunks {
			putStrokeChunk(chunk)
		}
	}

	func putCGRect( t:CGRect ) {
		putFloat64( Float64(t.origin.x))
		putFloat64( Float64(t.origin.y))
		putFloat64( Float64(t.size.width))
		putFloat64( Float64(t.size.height))
	}

	func putCGAffineTransform( t:CGAffineTransform ) {
		putFloat64( Float64(t.a))
		putFloat64( Float64(t.b))
		putFloat64( Float64(t.c))
		putFloat64( Float64(t.d))
		putFloat64( Float64(t.tx))
		putFloat64( Float64(t.ty))
	}
}