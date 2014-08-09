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
	case Eraser

	func set() {
		switch self {
			case .Pencil:
				UIColor.blackColor().set()

			case .Eraser:
				UIColor.whiteColor().colorWithAlphaComponent(0.8).set()
		}
	}

	var size:(CGFloat,CGFloat) {
		get {
			switch self {
				case .Pencil:
					return (0.5,2.0)

				case .Eraser:
					return (20.0,20.0)
			}
		}
	}

}

struct ControlPoint:Printable {
	let position:CGPoint
	let control:CGPoint

	var description:String {
		return "ControlPoint p:(\(position.x),\(position.y)) c:(\(control.x),\(control.y))"
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

class Stroke {

	struct Spar:Printable {
		let a:ControlPoint
		let b:ControlPoint

		init(a:ControlPoint, b:ControlPoint){
			self.a = a
			self.b = b
		}

		var description:String {
			return "Spar a:\(a) b:\(b)"
		}
	}

	var fill:Fill = Fill.Pencil
	var spars:[Spar] = []

	init( fill:Fill ) {
		self.fill = fill
	}
}
