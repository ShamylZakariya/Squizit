//
//  Match.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/15/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit
import Lilliput

let MatchSerializationCookie:[UInt8] = [109,116,99,104] // 'mtch'
let MatchSerializationVersion_V0:Int32 = 0


/**
	Represents a game match
*/
class Match {

	private var _drawings:[Drawing] = []
	private var _transforms:[CGAffineTransform] = []
	private var _stageSize = CGSize(width: 0, height: 0)
	private var _overlap:CGFloat = 0

	init(){}

	init( players:Int, stageSize:CGSize, overlap:CGFloat ){

		let rowHeight:CGFloat = CGFloat(round(stageSize.height / CGFloat(players)))
		_stageSize = stageSize
		_overlap = overlap

		let drawingSize = CGSize(width: stageSize.width, height: rowHeight + 2*overlap )
		let t:CGAffineTransform = CGAffineTransformMakeTranslation(0, 0)

		for i in 0 ..< players {
			_drawings.append(Drawing(width: Int(drawingSize.width), height: Int(drawingSize.height)))
			_transforms.append(CGAffineTransformMakeTranslation( 0, rowHeight * CGFloat(i) - overlap ))
		}
	}

	var drawings:[Drawing] { return _drawings }
	var transforms:[CGAffineTransform] { return _transforms }
	var overlap:CGFloat { return _overlap }

	func rectForPlayer( player:Int ) -> CGRect {
		let rowHeight:CGFloat = CGFloat(round(_stageSize.height / CGFloat(_drawings.count)))
		let drawingSize = CGSize(width: _stageSize.width, height: rowHeight + 2*_overlap )
		return CGRect(x: 0, y: rowHeight * CGFloat(player) - _overlap, width: drawingSize.width, height: drawingSize.height )
	}

	class func load( path:String ) -> Result<Match> {
		let openResult = BinaryFile.openForReading(path)

		if let error = openResult.error {
			return .Failure(Error(message: "unable to open \(path)"))
		}

		let file = openResult.binaryFile
		let size = file.size()

		if let error = size.error {
			return .Failure(Error(message: "unable to get file size from \(path)"))
		}

		let buffer = ByteBuffer(order: BigEndian(), capacity: Int(size.fileSize))
		let readResult = file.readBuffer(buffer)

		if let error = readResult.error {
			return .Failure(Error(message: "unable to read from \(path)"))
		}

		buffer.flip()

		return buffer.getMatch()
	}

	func serialize() -> Result<NSData> {
		var buffer = ByteBuffer(order: BigEndian(), capacity: ByteBuffer.requiredSizeForMatch(self))
		if buffer.putMatch(self) {
			return .Success( buffer.toNSData() )
		} else {
			return .Failure(Error(message: "unable to serialize to buffer - probably under capacity"))
		}
	}

	func save( path:String ) -> Result<Int> {

		var buffer = ByteBuffer(order: BigEndian(), capacity: ByteBuffer.requiredSizeForMatch(self))
		if buffer.putMatch(self) {

			buffer.flip()
			var fileOpenResult = BinaryFile.openForWriting(path, create: true)

			if let error = fileOpenResult.error {
				return .Failure(Error(message: "unable to open file \(path)"))
			}

			var file = fileOpenResult.binaryFile
			var fileWriteResult = file.writeBuffer(buffer)

			if let error = fileWriteResult.error {
				return .Failure(Error(message: "unable to write buffer to file \(path)"))
			}

			return .Success(fileWriteResult.byteCount)

		} else {
			return .Failure(Error(message: "unable to serialize to buffer - probably under capacity"))
		}
	}

	func render( backgroundColor:UIColor ) -> UIImage {

		UIGraphicsBeginImageContextWithOptions(_stageSize, true, 0)
		let context = UIGraphicsGetCurrentContext()

		backgroundColor.set()
		UIRectFillUsingBlendMode(CGRect(x: 0, y: 0, width: _stageSize.width, height: _stageSize.height), kCGBlendModeNormal)

		for (i,drawing) in enumerate(_drawings) {
			let transform = _transforms[i]

			CGContextSaveGState(context)
			CGContextConcatCTM(context, transform)

			let image = drawing.render()
			image.drawAtPoint(CGPoint(x: 0, y: 0), blendMode: kCGBlendModeMultiply, alpha: 1)

			CGContextRestoreGState(context)
		}

		var image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image
	}
}

extension ByteBuffer {

	class func requiredSizeForMatch( match:Match ) -> Int {
		let headerSize = sizeof(UInt8)*MatchSerializationCookie.count // #cookie
			+ 1*sizeof(Int32) // version #
			+ 2*sizeof(Float64) // width + height
			+ 1*sizeof(Float64) // overlap
			+ sizeof(Int32) // count of drawings & transforms
			+ match.drawings.count * ByteBuffer.requiredSizeForCGAffineTransform()

		var drawingSize = 0;
		for drawing in match.drawings {
			drawingSize += ByteBuffer.requiredSizeForDrawing(drawing)
		}

		return headerSize + drawingSize
	}

	func putMatch( match:Match ) -> Bool {
		putUInt8(MatchSerializationCookie)
		putInt32(MatchSerializationVersion_V0)
		putFloat64(Float64(match._stageSize.width))
		putFloat64(Float64(match._stageSize.height))
		putFloat64(Float64(match._overlap))
		putInt32(Int32(match.drawings.count))

		for i in 0 ..< match.drawings.count {
			putCGAffineTransform(match.transforms[i])
			if !putDrawing(match.drawings[i]) {
				return false
			}
		}

		return true;
	}

	func getMatch() -> Result<Match> {
		let cookie:[UInt8] = getUInt8(4)

		if ( cookie == MatchSerializationCookie ) {
			let version:Int32 = getInt32()

			if version == MatchSerializationVersion_V0 {
				return inflate_V0()
			} else {
				return .Failure(Error(message: "version # mismatch, unrecognized version: \(version)"))
			}
		} else {
			return .Failure(Error(message: "Match cookie mismatch - expected: \(MatchSerializationCookie) got: \(cookie)"))
		}
	}

	private func inflate_V0() -> Result<Match> {

		var match = Match()

		let stageSize = CGSize(width: CGFloat(getFloat64()), height: CGFloat(getFloat64()))
		match._stageSize = stageSize
		match._overlap = CGFloat(getFloat64())

		let count = getInt32()
		for i in 0 ..< count {
			if let t = getCGAffineTransform() {
				match._transforms.append(t)
			} else {
				return .Failure(Error(message: "Unable to extract transform for drawing \(i)"))
			}

			let drawingResult = getDrawing()
			if let error = drawingResult.error {
				return .Failure( error )
			}

			match._drawings.append(drawingResult.value)
		}

		//
		//	Success
		//

		return .Success(match)
	}

}