//
//  ByteBuffer_NSData.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/27/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import Lilliput

extension ByteBuffer {

	func toNSData() -> NSData {

		return NSData(bytes: self.bytes, length: self.capacity )

	}

	class func fromNSData( data:NSData ) -> ByteBuffer? {
		if data.length > 0 {
			var buffer = ByteBuffer(order: BigEndian(), capacity: data.length )
			memcpy( buffer.bytes + buffer.position, data.bytes, UInt(data.length) )
			return buffer
		}
		return nil
	}

}