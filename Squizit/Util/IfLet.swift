//
//  IfLet.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 1/14/15.
//	FROM: http://www.scottlogic.com/blog/2014/12/08/swift-optional-pyramids-of-doom.html
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//


import Foundation

public func if_let<T, U>(a: Optional<T>, b: Optional<U>, fn: (T, U) -> ()) {
	if let a = a {
		if let b = b {
			fn(a, b)
		}
	}
}

public func if_let<T, U, V>(a: Optional<T>, b: Optional<U>, c: Optional<V>, fn: (T, U, V) -> ()) {
	if let a = a {
		if let b = b {
			if let c = c {
				fn(a, b, c)
			}
		}
	}
}

public func if_let<T, U>(a: Optional<Any>, b: Optional<Any>, fn: (T, U) -> ()) -> Bool {
	if let a = a as? T {
		if let b = b as? U {
			fn(a, b)
			return true
		}
	}
	return false
}

public func if_let<T, U, V>(a: Optional<Any>, b: Optional<Any>, c: Optional<Any>, fn: (T, U, V) -> ()) -> Bool {
	if let a = a as? T {
		if let b = b as? U {
			if let c = c as? V {
				fn(a, b, c)
				return true
			}
		}
	}
	return false
}

public func if_let<T, U>(a: Optional<T>, b: Optional<U>, fn: (T, U) -> (), #elseFn: ()->()) {
	var allUnwrapped = false
	if let a = a {
		if let b = b {
			fn(a, b)
			allUnwrapped = true
		}
	}
	if !allUnwrapped {
		elseFn()
	}
}

public func if_let<T, U, V>(a: Optional<T>, b: Optional<U>, c: Optional<V>, fn: (T, U, V) -> (), #elseFn: ()->()) {
	var allUnwrapped = false
	if let a = a {
		if let b = b {
			if let c = c {
				fn(a, b, c)
				allUnwrapped = true
			}
		}
	}
	if !allUnwrapped {
		elseFn()
	}
}