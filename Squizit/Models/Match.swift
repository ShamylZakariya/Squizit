//
//  Match.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/15/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

let MatchSerializationCookie:[UInt8] = [109,116,99,104] // 'mtch'
let MatchSerializationVersion_V0:Int32 = 0


/**
	Represents a game match
*/
class Match {

	private var _players:Int = 0
	private var _drawings:[Drawing] = []
	private var _viewports:[CGRect] = []
	private var _stageSize = CGSize.zeroSize
	private var _overlap:CGFloat = 0

	init(){}

	init( players:Int, stageSize:CGSize, overlap:CGFloat ){

		_stageSize = stageSize
		_overlap = overlap
		_players = players

		for i in 0 ..< players {
			_drawings.append(Drawing())
			_viewports.append(viewportForPlayer(i))
		}
	}

	var players:Int { return _players }
	var drawings:[Drawing] { return _drawings }
	var viewports:[CGRect] { return _viewports }
	var overlap:CGFloat { return _overlap }

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

	func render( backgroundColor:UIColor? = nil, scale:CGFloat = 0, watermark:Bool = false ) -> UIImage {

		//
		// first, render the match itself over a white background
		//

		UIGraphicsBeginImageContextWithOptions( _stageSize, true, scale )
		let context = UIGraphicsGetCurrentContext()
		let rect = CGRect(x: 0, y: 0, width: _stageSize.width, height: _stageSize.height)

		UIColor.whiteColor().set()
		UIRectFillUsingBlendMode(rect, kCGBlendModeNormal)

		for (i,drawing) in enumerate(_drawings) {
			let viewport = _viewports[i]

			CGContextSaveGState(context)
			CGContextTranslateCTM(context, viewport.origin.x, viewport.origin.y)
			CGContextClipToRect(context, CGRect(x: 0, y: 0, width: viewport.width, height: viewport.height))

			drawing.draw()

			CGContextRestoreGState(context)
		}

		if watermark {
			let watermark = SquizitTheme.exportWatermarkImage()
			let margin = _stageSize.width * 0.025
			let scale = _stageSize.width * 0.1 / watermark.size.width
			let size = CGSize( width: watermark.size.width * scale, height: watermark.size.height * scale )
			let watermarkRect = CGRect( x: _stageSize.width - margin - size.width, y: _stageSize.height - margin - size.height, width: size.width, height: size.height ).integerRect

			watermark.drawInRect( watermarkRect, blendMode: kCGBlendModeNormal, alpha: 1)
		}


		var rendering = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		if let backgroundColor = backgroundColor {

			//
			// now, multiply composite this over an image filled with backgroundColor
			//

			UIGraphicsBeginImageContextWithOptions(_stageSize, true, scale)

			backgroundColor.set()
			UIRectFillUsingBlendMode(rect, kCGBlendModeNormal)

			rendering.drawAtPoint(CGPoint(x: 0, y: 0), blendMode: kCGBlendModeMultiply, alpha: 1)

			rendering = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
		}


		return rendering
	}

	private func viewportForPlayer( player:Int ) -> CGRect {
		let rowHeight:CGFloat = CGFloat(round(_stageSize.height / CGFloat(_players)))
		let size = CGSize(width: _stageSize.width, height: rowHeight + 2*_overlap )

		return CGRect(x: 0, y: (rowHeight * CGFloat(player)) - _overlap, width: size.width, height: size.height )
	}
}

extension ByteBuffer {

	class func requiredSizeForMatch( match:Match ) -> Int {
		return sizeof(UInt8)*MatchSerializationCookie.count // #cookie
			+ 1*sizeof(Int32) // version #
			+ 2*sizeof(Float64) // width + height
			+ 1*sizeof(Float64) // overlap
			+ sizeof(Int32) // count of viewports & drawings
			+ match.players * ByteBuffer.requiredSizeForCGRect() // total space for viewports
			+ match.drawings.reduce(0, combine: { (totalSize:Int, drawing:Drawing) -> Int in
				return totalSize + ByteBuffer.requiredSizeForDrawing(drawing) // total space for drawings
			})
	}

	func putMatch( match:Match ) -> Bool {
		putUInt8(MatchSerializationCookie)
		putInt32(MatchSerializationVersion_V0)
		putFloat64(Float64(match._stageSize.width))
		putFloat64(Float64(match._stageSize.height))
		putFloat64(Float64(match._overlap))
		putInt32(Int32(match.players))

		for i in 0 ..< match.players {
			putCGRect(match.viewports[i])
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

			switch version {
				case MatchSerializationVersion_V0:
					return inflate_V0()

				default:
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
		match._players = Int(getInt32())

		for i in 0 ..< match._players {

			if let viewport = getCGRect() {
				match._viewports.append(viewport)
			} else {
				return .Failure(Error(message: "Unable to extract viewport for drawing \(i)"))
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