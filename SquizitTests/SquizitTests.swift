//
//  SquizitTests.swift
//  SquizitTests
//
//  Created by Shamyl Zakariya on 8/9/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit
import XCTest

private func randRange( var min:CGFloat, var max: CGFloat ) -> CGFloat {
	if ( max < min ) {
		swap( &max, &min )
	}

	return min + (CGFloat(drand48()) * (max - min))
}

private func randomColor() -> UIColor {
	let red = drand48()
	let green = fract(red + drand48() * 0.5)
	let blue = fract( green + drand48() * 0.5)
	let alpha = drand48()
	return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
}

private func randomPoint() -> CGPoint {
	return CGPoint(x: randRange(-100, 100), y: randRange(-100, 100))
}

class BinaryCoderTests: XCTestCase {

    override func setUp() {
        super.setUp()
	}

    override func tearDown() {
        super.tearDown()
    }

	func testUInt8Coding() {
		var coder = MutableBinaryCoder(order: nativeOrder())

		let ints:[UInt8] = [0,1,2,3,4,5,6,7,8]
		for i in ints {
			coder.putUInt8(i)
		}

		coder.rewind()

		for i in ints {
			let v = coder.getUInt8()
			XCTAssertEqual(i, v, "Deserialized UInt8s should be same")
		}
	}

	func testUInt8ArrayCoding() {
		var coder = MutableBinaryCoder(order: nativeOrder())

		let ints:[UInt8] = [0,1,2,3,4,5,6,7,8]
		coder.putUInt8(ints)
		coder.rewind()

		let deserialized:[UInt8] = coder.getUInt8(ints.count)
		for (index,value) in enumerate(ints) {
			XCTAssertEqual(value, deserialized[index], "Deserialized UInt8s should be same")
		}
	}

	func testUInt16Coding() {
		var coder = MutableBinaryCoder(order: nativeOrder())
		let ints:[UInt16] = [UInt16.min,1000,1001,1002,1003,UInt16.max]
		for i in ints {
			coder.putUInt16(i)
		}

		coder.rewind()

		for i in ints {
			let v = coder.getUInt16()
			XCTAssertEqual(i, v, "Deserialized UInt16s should be same")
		}
	}

	func testUInt16ArrayCoding() {
		var coder = MutableBinaryCoder(order: nativeOrder())

		let ints:[UInt16] = [UInt16.min,1000,1001,1002,1003,UInt16.max]
		coder.putUInt16(ints)
		coder.rewind()

		let deserialized:[UInt16] = coder.getUInt16(ints.count)
		for (index,value) in enumerate(ints) {
			XCTAssertEqual(value, deserialized[index], "Deserialized UInt8s should be same")
		}
	}

	func testUInt32Coding() {
		var coder = MutableBinaryCoder(order: nativeOrder())
		let ints:[UInt32] = [UInt32.min,1000000,1000001,1000002,1000003,UInt32.max]
		for i in ints {
			coder.putUInt32(i)
		}

		coder.rewind()

		for i in ints {
			let v = coder.getUInt32()
			XCTAssertEqual(i, v, "Deserialized UInt32s should be same")
		}
	}

	func testUInt32ArrayCoding() {
		var coder = MutableBinaryCoder(order: nativeOrder())

		let ints:[UInt32] = [UInt32.min,1000000,1000001,1000002,1000003,UInt32.max]
		coder.putUInt32(ints)
		coder.rewind()

		let deserialized:[UInt32] = coder.getUInt32(ints.count)
		for (index,value) in enumerate(ints) {
			XCTAssertEqual(value, deserialized[index], "Deserialized UInt32s should be same")
		}
	}

	func testFloat32Coding() {
		var coder = MutableBinaryCoder(order: nativeOrder())

		var floats:[Float32] = []
		for i in 0 ..< 100 {
			floats.append( Float32(i) * Float32(M_PI) )
		}

		for i in floats {
			coder.putFloat32(i)
		}

		coder.rewind()

		for i in floats {
			let v = coder.getFloat32()
			XCTAssertEqual(i, v, "Deserialized Float32s should be same")
		}
	}

	func testFloat32ArrayCoding() {
		var coder = MutableBinaryCoder(order: nativeOrder())

		var floats:[Float32] = []
		for i in 0 ..< 100 {
			floats.append( Float32(i) * Float32(M_PI) )
		}

		coder.putFloat32(floats)
		coder.rewind()

		let deserialized:[Float32] = coder.getFloat32(floats.count)
		for (index,value) in enumerate(floats) {
			XCTAssertEqual(value, deserialized[index], "Deserialized Float32s should be same")
		}
	}

	func testFloat64Coding() {
		var coder = MutableBinaryCoder(order: nativeOrder())

		var floats:[Float64] = []
		for i in 0 ..< 100 {
			floats.append( Float64(i) * Float64(M_PI) * 111222333.555 )
		}

		for i in floats {
			coder.putFloat64(i)
		}

		coder.rewind()

		for i in floats {
			let v = coder.getFloat64()
			XCTAssertEqual(i, v, "Deserialized Float64s should be same")
		}
	}

	func testFloat64ArrayCoding() {
		var coder = MutableBinaryCoder(order: nativeOrder())

		var floats:[Float64] = []
		for i in 0 ..< 100 {
			floats.append( Float64(i) * Float64(M_PI) * 111222333.555 )
		}

		coder.putFloat64(floats)
		coder.rewind()

		let deserialized:[Float64] = coder.getFloat64(floats.count)
		for (index,value) in enumerate(floats) {
			XCTAssertEqual(value, deserialized[index], "Deserialized Float64s should be same")
		}
	}

	func testUTF8Encoding() {
		var coder = MutableBinaryCoder(order: nativeOrder())
		let str = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

		coder.putTerminatedUTF8(str)
		coder.rewind()

		let deserialized = coder.getTerminatedUTF8()
		XCTAssertEqual(str, deserialized, "Deserialized UTF8 strings should be same")
	}

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
		var buffer = MutableBinaryCoder(order: BigEndian())

		let cpA = ControlPoint(position: CGPoint(x: 0, y: 0), control: CGPoint(x: 100, y: 100))

		buffer.putControlPoint(cpA)
		buffer.rewind()
		if let cpAPrime = buffer.getControlPoint() {
			XCTAssertEqual( cpA, cpAPrime, "Deserialized ControlPoint should equal original")
		} else {
			XCTFail("Expected to deserialize control point - got nil")
		}
	}
    
    func testStrokeSerialization() {

		var buffer = MutableBinaryCoder(order: BigEndian())

		var strokeA = Stroke(fill: Fill.Pencil)
		srand48(123)

		for i in 0 ..< 20 {
			var chunk = Stroke.Chunk(
				start: Stroke.Chunk.Spar(
					a: ControlPoint(position: randomPoint(), control: randomPoint()),
					b: ControlPoint(position: randomPoint(), control: randomPoint())),
				end: Stroke.Chunk.Spar(
					a: ControlPoint(position: randomPoint(), control: randomPoint()),
					b: ControlPoint(position: randomPoint(), control: randomPoint()))
			)

			strokeA.chunks.append(chunk)
		}

		buffer.putStroke(strokeA)
		buffer.rewind()

		if let strokeAPrime = buffer.getStroke() {
			XCTAssertEqual(strokeA, strokeAPrime, "Deserialized Stroke should equal original")
		} else {
			XCTFail("Wasn't able to deserialize Stroke")
		}
    }

	func testColorSerialization() {
		let count = 33
		var buffer = MutableBinaryCoder(order: BigEndian())

		var colors:[UIColor] = []
		for i in 0 ..< count {
			let color = randomColor()
			colors.append(color)
			buffer.putColor(color)
		}

		buffer.rewind()

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
		var drawing = Drawing()

		// draw a circle
		let steps = 36
		let radianIncrement = (2 * CGFloat(M_PI)) / CGFloat(steps)
		let radius:CGFloat = 100.0
		let center = CGPoint( x: 256, y: 256 )
		let width:CGFloat = 20.0

		func spar( radians:CGFloat ) -> Stroke.Chunk.Spar {
			let ap = center.add(CGPoint(x: (radius-width) * cos(radians), y: (radius-width) * sin(radians)))
			let ac = ap.add(CGPoint( x: cos(radians), y: sin(radians)))
			let bp = center.add(CGPoint(x: (radius+width) * cos(radians), y: (radius+width) * sin(radians)))
			let bc = bp.add(CGPoint( x: cos(radians), y: sin(radians)))

			return Stroke.Chunk.Spar(a: ControlPoint(position: ap, control: ac), b: ControlPoint(position: bp, control: bc))
		}

		var stroke = Stroke(fill: .Pencil)
		var radians:CGFloat = 0;
		for i in 0 ..< steps {
			let nextRadians = radians + radianIncrement
			stroke.chunks.append(Stroke.Chunk( start: spar(radians), end:spar(nextRadians)))
		}

		drawing.addStroke(stroke)

		return drawing
	}

	var drawingSaveFile:String = NSTemporaryDirectory().stringByAppendingPathComponent("test-drawing.bin")

	func testDrawingSerialization() {

		var drawing = newDrawing()
		var buffer = MutableBinaryCoder(order: BigEndian())
		buffer.putDrawing(drawing)

		XCTAssertGreaterThan(buffer.length, 0, "Expect serialized drawing to take up more than zero bytes")

		buffer.rewind()
		var drawingPrimeResult = buffer.getDrawing()
		XCTAssert(drawingPrimeResult.error == nil, "Expect to successfully deserialize drawing from buffer")

		var drawingPrime = drawingPrimeResult.value

		// check if strokes are the same
		XCTAssertEqual(drawing.strokes.count, drawingPrime.strokes.count, "Expect deserialized drawing to have same # of strokes")

		for (i,stroke) in enumerate(drawing.strokes){
			XCTAssertEqual(stroke, drawingPrime.strokes[i], "Expect strokes to be equal")
		}

		let viewport = CGRect(x: 0, y: 0, width: 512, height: 512)
		var drawingImage = drawing.render(viewport)
		var drawingImagePrime = drawingPrimeResult.value.render(viewport)

		var drawingImageData = UIImagePNGRepresentation(drawingImage.image)
		var drawingImageDataPrime = UIImagePNGRepresentation(drawingImagePrime.image)

		XCTAssert(drawingImageData.length > 0, "Expect rendered drawing's PNG data rep to have > 0 length")
		XCTAssert(drawingImageDataPrime.length > 0, "Expect deserialized rendered drawing's PNG data rep to have > 0 length")

		// now check bytes, see if ==
		XCTAssert(drawingImageData.isEqualToData(drawingImageDataPrime), "Expect deserialized drawing's rendered image data to equal source")
	}
}
