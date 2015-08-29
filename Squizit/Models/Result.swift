//
//  Result.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/10/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation

public final class Box<T> {
	let value: T

	init(_ value: T) {
		self.value = value
	}
}

public struct Error {

	public let message: String
	
	public init(message: String ) {
		self.message = message
	}
}

public enum Result<T> {
	case Success(Box<T>)
	case Failure(Error)
	
	public var error: Error? {
		switch self {
		case .Success:
			return nil
		case .Failure(let error):
			return error
		}
	}
	
	public var value: T! {
		switch self {
		case .Success(let value):
			return value.value
		case .Failure:
			return nil
		}
	}
}