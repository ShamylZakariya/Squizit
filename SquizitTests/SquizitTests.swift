//
//  SquizitTests.swift
//  SquizitTests
//
//  Created by Shamyl Zakariya on 8/9/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit
import XCTest
import Lilliput

func randRange( var min:CGFloat, var max: CGFloat ) -> CGFloat {
	if ( max < min ) {
		swap( &max, &min )
	}

	return min + (CGFloat(drand48()) * (max - min))
}

func randomColor() -> UIColor {
	let red = drand48()
	let green = fract(red + drand48() * 0.5)
	let blue = fract( green + drand48() * 0.5)
	let alpha = drand48()
	return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
}

func randomPoint() -> CGPoint {
	return CGPoint(x: randRange(-100, 100), y: randRange(-100, 100))
}

class SquizitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
		NSFileManager.defaultManager().removeItemAtPath(drawingSaveFile, error: nil)
	}

    override func tearDown() {
		NSFileManager.defaultManager().removeItemAtPath(drawingSaveFile, error: nil)
        super.tearDown()
    }

	func testControlPointSerialization() {
		var buffer:ByteBuffer = ByteBuffer(order: BigEndian(), capacity: 4096)

		let cpA = ControlPoint(position: CGPoint(x: 0, y: 0), control: CGPoint(x: 100, y: 100))

		buffer.putControlPoint(cpA)
		buffer.flip()
		let cpAPrime = buffer.getControlPoint()

		XCTAssertEqual( cpA, cpAPrime, "Deserialized ControlPoint should equal original")
	}
    
    func testStrokeSerialization() {

		var buffer:ByteBuffer = ByteBuffer(order: BigEndian(), capacity: 4096)

		var strokeA = Stroke(fill: Fill.Pencil)
		srand48(123)

		for i in 0 ..< 20 {
			strokeA.spars.append(Stroke.Spar(
				a: ControlPoint(position: randomPoint(), control: randomPoint()),
				b: ControlPoint(position: randomPoint(), control: randomPoint())))
		}

		buffer.putStroke(strokeA)
		buffer.flip()

		let strokeAPrime = buffer.getStroke()

		XCTAssertEqual(strokeA, strokeAPrime, "Deserialized Stroke should equal original")
    }

	func testColorSerialization() {
		let count = 33

		// make buffer big enough for our random colors
		var buffer:ByteBuffer = ByteBuffer(order: BigEndian(), capacity: count * ByteBuffer.requiredSpaceForColor())

		var colors:[UIColor] = []
		for i in 0 ..< count {
			let color = randomColor()
			colors.append(color)
			buffer.putColor(color)
		}

		buffer.flip()

		for i in 0 ..< count {
			var maybeColorPrime = buffer.getColor()
			XCTAssertNotNil(maybeColorPrime, "Expect to deserialize a color")

			if let colorPrime:UIColor = maybeColorPrime {
				XCTAssert(colorPrime.hasRGBComponents, "Expect deserialized color to have RGB components")
				let color = colors[i]
				XCTAssertEqual(color.redComponent!, colorPrime.redComponent!, "Expect equal red components")
				XCTAssertEqual(color.greenComponent!, colorPrime.greenComponent!, "Expect equal green components")
				XCTAssertEqual(color.blueComponent!, colorPrime.blueComponent!, "Expect equal blue components")
				XCTAssertEqual(color.alphaComponent!, colorPrime.alphaComponent!, "Expect equal alpha components")
			}
		}
	}

	func newDrawing() -> Drawing {
		var drawing = Drawing(width: 512, height: 512)

		// draw a circle
		let steps = 36
		let radianIncrement = (2 * CGFloat(M_PI)) / CGFloat(steps)
		let radius:CGFloat = 100.0
		let center = CGPoint( x: 256, y: 256 )
		let width:CGFloat = 20.0

		func spar( radians:CGFloat ) -> Stroke.Spar {
			let ap = center.add(CGPoint(x: (radius-width) * cos(radians), y: (radius-width) * sin(radians)))
			let ac = ap.add(CGPoint( x: cos(radians), y: sin(radians)))
			let bp = center.add(CGPoint(x: (radius+width) * cos(radians), y: (radius+width) * sin(radians)))
			let bc = bp.add(CGPoint( x: cos(radians), y: sin(radians)))

			return Stroke.Spar(a: ControlPoint(position: ap, control: ac), b: ControlPoint(position: bp, control: bc))
		}

		var radians:CGFloat = 0;
		for i in 0 ..< steps {
			let nextRadians = radians + radianIncrement

			var stroke = Stroke(fill: .Pencil)
			stroke.spars.append(spar( radians ))
			stroke.spars.append(spar( nextRadians ))

			drawing.addStroke(stroke)
		}

		return drawing
	}

	var drawingSaveFile:String = NSTemporaryDirectory().stringByAppendingPathComponent("test-drawing.bin")

	func testDrawingSerialization() {

		var drawing = newDrawing()

		var buffer = ByteBuffer(order: BigEndian(), capacity: ByteBuffer.requiredSizeForDrawing(drawing))
		XCTAssert( buffer.putDrawing(drawing), "Expect to serialize drawing" )


		buffer.flip()
		var drawingPrimeResult = buffer.getDrawing()
		XCTAssert(drawingPrimeResult.error == nil, "Expect to successfully deserialize drawing from buffer")

		var drawingPrime = drawingPrimeResult.value

		// check if drawing's width/height are same
		XCTAssert(CGSizeEqualToSize(drawing.size, drawingPrime.size), "Expect deserialized drawing to have same size")

		// check if strokes are the same
		XCTAssertEqual(drawing.strokes.count, drawingPrime.strokes.count, "Expect deserialized drawing to have same # of strokes")

		for (i,stroke) in enumerate(drawing.strokes){
			XCTAssertEqual(stroke, drawingPrime.strokes[i], "Expect strokes to be equal")
		}

		var drawingImage = drawing.render()
		var drawingImagePrime = drawingPrimeResult.value.render()

		var drawingImageData = UIImagePNGRepresentation(drawingImage)
		var drawingImageDataPrime = UIImagePNGRepresentation(drawingImagePrime)

		XCTAssert(drawingImageData.length > 0, "Expect rendered drawing's PNG data rep to have > 0 length")
		XCTAssert(drawingImageDataPrime.length > 0, "Expect deserialized rendered drawing's PNG data rep to have > 0 length")

		// now check bytes, see if ==
		XCTAssert(drawingImageData.isEqualToData(drawingImageDataPrime), "Expect deserialized drawing's rendered image data to equal source")
	}
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
