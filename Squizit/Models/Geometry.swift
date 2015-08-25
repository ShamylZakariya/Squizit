//
//  Geometry.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/21/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {

	init( center: CGPoint, size: CGSize ){
		self.init(x:center.x - size.width/2, y:center.y - size.height/2, width: size.width, height: size.height )
	}

	init( center: CGPoint, radius: CGFloat ){
		self.init(x:center.x - radius, y:center.y - radius, width: 2*radius, height: 2*radius )
	}

	var center:CGPoint {
		return CGPoint(x: midX, y: midY)
	}

	static func rectByFitting( points:CGPoint... ) -> CGRect {
		var minX = CGFloat.max
		var maxX = CGFloat.min
		var minY = CGFloat.max
		var maxY = CGFloat.min
		for p in points {
			minX = min( minX, p.x )
			maxX = max( maxX, p.x )
			minY = min( minY, p.y )
			maxY = max( maxY, p.y )
		}

		return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY )
	}

}

extension CGRect {

	func rectByAddingTopMargin( m:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y + m, width: size.width, height: size.height - m )
	}

	func rectByAddingBottomMargin( m:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height - m )
	}

	func rectByAddingMargins( topMargin:CGFloat, bottomMargin:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y + topMargin, width: size.width, height: size.height - topMargin - bottomMargin )
	}
}

extension CGPoint {

	func scale( a:CGFloat ) -> CGPoint {
		return CGPoint(x: x * a, y: y * a )
	}

	func add( a: CGPoint ) -> CGPoint {
		return CGPoint( x: x + a.x, y: y + a.y )
	}

	func subtract( a: CGPoint ) -> CGPoint {
		return CGPoint( x: x - a.x, y: y - a.y )
	}

	func distanceSquared( a:CGPoint ) -> CGFloat {
		let Dx = a.x - x
		let Dy = a.y - y
		return (Dx*Dx) + (Dy*Dy)
	}

	func distance( a:CGPoint ) -> CGFloat {
		let Dx = a.x - x
		let Dy = a.y - y
		return sqrt((Dx*Dx) + (Dy*Dy))
	}

	func integerPoint() -> CGPoint {
		return CGPoint(x: round(x), y: round(y))
	}
}

extension CGSize {

	func scale( a:CGFloat ) -> CGSize {
		return CGSize(width: self.width * a, height: self.height * a)
	}

}

struct LineSegment {
	let firstPoint:CGPoint
	let secondPoint:CGPoint

	init() {
		self.firstPoint = CGPoint.zeroPoint
		self.secondPoint = CGPoint.zeroPoint
	}

	init(firstPoint:CGPoint, secondPoint:CGPoint) {
		self.firstPoint = firstPoint
		self.secondPoint = secondPoint
	}

	func perpendicular( relativeLength fraction:CGFloat ) -> LineSegment {
		let x0 = firstPoint.x
		let y0 = firstPoint.y
		let x1 = secondPoint.x
		let y1 = secondPoint.y

		let dx = x1 - x0
		let dy = y1 - y0

		let xa = x1 + ((fraction/2) * dy)
		let ya = y1 - ((fraction/2) * dx)
		let xb = x1 - ((fraction/2) * dy)
		let yb = y1 + ((fraction/2) * dx)

		return LineSegment(firstPoint: CGPoint(x: xa, y: ya), secondPoint: CGPoint(x: xb, y: yb))
	}

	func perpendicular( #absoluteLength:CGFloat ) -> LineSegment {

		let x0 = firstPoint.x
		let y0 = firstPoint.y
		let x1 = secondPoint.x
		let y1 = secondPoint.y
		let length = self.length()

		if length > 1e-4
		{
			let dx = (x1 - x0)/length
			let dy = (y1 - y0)/length

			let xa = x1 + ((absoluteLength/2) * dy)
			let ya = y1 - ((absoluteLength/2) * dx)
			let xb = x1 - ((absoluteLength/2) * dy)
			let yb = y1 + ((absoluteLength/2) * dx)

			return LineSegment(firstPoint: CGPoint(x: xa, y: ya), secondPoint: CGPoint(x: xb, y: yb))
		}

		// zero length, no-op
		return LineSegment(firstPoint: CGPoint(x:x1,y:y1), secondPoint: CGPoint(x:x1,y:y1))
	}


	func length() -> CGFloat {
		return sqrt(lengthSquared())
	}

	func lengthSquared() -> CGFloat {
		let dx = firstPoint.x - secondPoint.x;
		let dy = firstPoint.y - secondPoint.y;
		return (dx*dx) + (dy*dy);
	}

	func description() -> String {
		return "(\(firstPoint.x),\(firstPoint.y))(\(secondPoint.x),\(secondPoint.y))"
	}
}

struct CubicBezierInterpolator {

	let points:[CGPoint]

	init( a:CGPoint, b:CGPoint, c:CGPoint, d:CGPoint ) {
		points = [a,b,c,d]
	}

	func bezierPoint( t: CGFloat ) -> CGPoint {
		// from http://ciechanowski.me/blog/2014/02/18/drawing-bezier-curves/

		let Nt = 1.0 - t
		let A = Nt * Nt * Nt
		let B = 3.0 * Nt * Nt * t
		let C = 3.0 * Nt * t * t
		let D = t * t * t

		var p = points[0].scale(A)
		p = p.add( points[1].scale(B) )
		p = p.add( points[2].scale(C) )
		p = p.add( points[3].scale(D) )

		return p
	}

	func bezierPoint_Geometry( T: CGFloat ) -> CGPoint {
		// http://en.wikipedia.org/wiki/Bézier_curve

		let Q0 = interpolate(points[0], points[1], T )
		let Q1 = interpolate(points[1], points[2], T )
		let Q2 = interpolate(points[2], points[3], T )
		let R0 = interpolate(Q0,Q1,T)
		let R1 = interpolate(Q1,Q2,T)

		return interpolate(R0,R1,T)
	}


	func recommendedSubdivisions() -> Int {
		// from http://ciechanowski.me/blog/2014/02/18/drawing-bezier-curves/

		let L0 = points[0].distance(points[1])
		let L1 = points[1].distance(points[2])
		let L2 = points[2].distance(points[3])
		let ApproximateLength = L0 + L1 + L2

		let Min:CGFloat = 10.0
		let Segs:CGFloat = ApproximateLength / 30.0
		let Slope:CGFloat = 0.6

		return Int(ceil(sqrt( (Segs*Segs) * Slope + (Min*Min))))
	}
}

func distance( a:CGPoint, b:CGPoint ) -> CGFloat {
	let dx = a.x - b.x
	let dy = a.y - b.y
	return sqrt((dx*dx) + (dy*dy))
}

func distanceSquared( a:CGPoint, b:CGPoint ) -> CGFloat {
	let dx = a.x - b.x
	let dy = a.y - b.y
	return (dx*dx) + (dy*dy)
}

// return point t distance from a to b
func interpolate( a: CGPoint, b: CGPoint, t: CGFloat ) -> CGPoint {
	let Dx = b.x - a.x
	let Dy = b.y - a.y
	return CGPoint(x: a.x + Dx * t, y: a.y + Dy * t )
}

func clamp<T:Comparable>( value:T, lowerBound:T, upperBound:T ) -> T {
	if ( value < lowerBound ) {
		return lowerBound;
	} else if ( value > upperBound ) {
		return upperBound;
	}

	return value;
}

func fract( f:Float ) -> Float {
	return f - floor(f)
}

func fract( f:Double ) -> Double {
	return f - floor(f)
}
