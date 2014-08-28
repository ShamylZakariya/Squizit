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

}