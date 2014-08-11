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

		var buffer:ByteBuffer? = drawing.serialize()
		XCTAssert(buffer != nil, "Expect to serialize drawing to buffer")

		var drawingPrimeResult = Drawing.load(buffer!)
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

	func testDrawingSavingAndLoading() {

		var drawing = newDrawing()
		drawing.save(drawingSaveFile)

		var drawingPrimeResult = Drawing.load(drawingSaveFile)

		println("saving to \(drawingSaveFile)")

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
