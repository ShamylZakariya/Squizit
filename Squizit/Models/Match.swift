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
	private var _stageSize = CGSize.zero
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

	class func load( fileUrl:NSURL ) -> Result<Match> {
		let reader = BinaryCoder(order: BigEndian(), contentsOfURL: fileUrl )
		return reader.getMatch()
	}

	class func load( data:NSData ) -> Result<Match> {

		// first try native byte ordering
		var reader = BinaryCoder(order:nativeOrder(), data: data)
		let readResult = reader.getMatch()
		switch readResult {
			case .Success( let value ):
				return .Success(value)

			case .Failure:
				// native failed, this is an older file, in BigEndian
				reader = BinaryCoder(order:foreignOrder(), data: data)
				return reader.getMatch()
		}
	}

	func serialize() -> Result<NSData> {

		// there's no failure case here, but in the future there might be, so I'm keeing the Result<NSData>

		let writer = MutableBinaryCoder(order:nativeOrder())
		writer.putMatch(self)
		return .Success(Box(writer.data))
	}

	func save( fileUrl:NSURL ) -> Result<Int> {

		let serializationResult = serialize()
		if let error = serializationResult.error {
			return Result.Failure(error)
		}

		serializationResult.value.writeToURL(fileUrl, atomically: true)
		return .Success(Box(serializationResult.value.length))
	}

	func render( backgroundColor:UIColor? = nil, scale:CGFloat = 0, watermark:Bool = false ) -> UIImage {

		//
		// first, render the match itself over a white background
		//

		UIGraphicsBeginImageContextWithOptions( _stageSize, true, scale )
		let context = UIGraphicsGetCurrentContext()
		let rect = CGRect(x: 0, y: 0, width: _stageSize.width, height: _stageSize.height)

		UIColor.whiteColor().set()
		UIRectFillUsingBlendMode(rect, CGBlendMode.Normal)

		for (i,drawing) in _drawings.enumerate() {
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
			let watermarkRect = CGRect( x: _stageSize.width - margin - size.width, y: _stageSize.height - margin - size.height, width: size.width, height: size.height ).integral

			watermark.drawInRect( watermarkRect, blendMode: CGBlendMode.Normal, alpha: 1)
		}


		var rendering = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		if let backgroundColor = backgroundColor {

			//
			// now, multiply composite this over an image filled with backgroundColor
			//

			UIGraphicsBeginImageContextWithOptions(_stageSize, true, scale)

			backgroundColor.set()
			UIRectFillUsingBlendMode(rect, CGBlendMode.Normal)

			rendering.drawAtPoint(CGPoint(x: 0, y: 0), blendMode: CGBlendMode.Multiply, alpha: 1)

			rendering = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
		}


		return rendering
	}

	private func viewportForPlayer( player:Int ) -> CGRect {
		let rowHeight:CGFloat = CGFloat(round(_stageSize.height / CGFloat(_players)))

		switch player {
		case _players - 1:
			return CGRect(x:0, y:_stageSize.height-rowHeight, width: _stageSize.width, height: rowHeight)
		default:
			return CGRect(x: 0, y: (rowHeight * CGFloat(player)), width: _stageSize.width, height: rowHeight + _overlap )
		}
	}
}

extension BinaryCoder {

	func getMatch() -> Result<Match> {
		if remaining < 4 * sizeof(UInt8) {
			return .Failure(Error(message: "Unable to read cookie -- empty file? file length:\(length)"))
		}

		let cookie:[UInt8] = getUInt8(4)
		if ( cookie == MatchSerializationCookie ) {

			if remaining >= sizeof(Int32) {
				let version:Int32 = getInt32()

				switch version {
					case MatchSerializationVersion_V0:
						return inflate_V0()

					default:
						return .Failure(Error(message: "version # mismatch, unrecognized version: \(version)"))
				}
			} else {
				return .Failure(Error(message: "Data exhausted. Unable to extract version #. Remaining bytes: \(remaining)"))
			}
		} else {
			return .Failure(Error(message: "Match cookie mismatch - expected: \(MatchSerializationCookie) got: \(cookie)"))
		}
	}

	private func inflate_V0() -> Result<Match> {

		let match = Match()

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

		return .Success(Box(match))
	}
}

extension MutableBinaryCoder {

	func putMatch( match:Match ) {
		putUInt8(MatchSerializationCookie)
		putInt32(MatchSerializationVersion_V0)
		putFloat64(Float64(match._stageSize.width))
		putFloat64(Float64(match._stageSize.height))
		putFloat64(Float64(match._overlap))
		putInt32(Int32(match.players))

		for i in 0 ..< match.players {
			putCGRect(match.viewports[i])
			putDrawing(match.drawings[i])
		}
	}

}