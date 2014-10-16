//
//  BinaryCoder.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 10/16/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation

/**
	Adaptation of https://github.com/jkolb/Lilliput
	BinaryCoder wraps an NSMutableData instance, and makes it easy to put or get basic types like ints, floats, strings, in an endian-safe manner.
*/

class BinaryCoder {

	private var _data:NSMutableData!
	private var _order:ByteOrder!
	private let _bits = UnsafeMutablePointer<UInt8>.alloc(sizeof(UIntMax))
	private var _position:Int = 0

	init( order:ByteOrder ) {
		_order = order;
		_data = NSMutableData(capacity: 0)
	}

	init( order:ByteOrder, data:NSData ) {
		_order = order;
		_data = NSMutableData(data: data)
	}

	init( order:ByteOrder, contentsOfURL url:NSURL ) {
		_order = order;
		_data = NSMutableData(contentsOfURL:url)
	}

	deinit {
		_bits.dealloc(sizeof(UIntMax))
	}

	var position: Int {
		get {
			return _position
		}
		set {

			if (newValue < 0 || newValue > _data.length) {
				fatalError("Illegal position")
			}

			_position = newValue
		}
	}

	func rewind() { position = 0; }

	var length:Int { return _data.length }

	// MARK: Reading

	func getInt8() -> Int8 {
		return Int8(bitPattern: getUInt8())
	}

	func getInt16() -> Int16 {
		return Int16(bitPattern: getUInt16())
	}

	func getInt32() -> Int32 {
		return Int32(bitPattern: getUInt32())
	}

	func getInt64() -> Int64 {
		return Int64(bitPattern: getUInt64())
	}

	func getUInt8() -> UInt8 {
		return UnsafePointer<UInt8>(_data.bytes)[position++]
	}

	func getUInt16() -> UInt16 {
		return _order.toNative(getBits())
	}

	func getUInt32() -> UInt32 {
		return _order.toNative(getBits())
	}

	func getUInt64() -> UInt64 {
		return _order.toNative(getBits())
	}

	func getFloat32() -> Float32 {
		UnsafeMutablePointer<UInt32>(_bits).memory = getUInt32()
		return UnsafePointer<Float32>(_bits).memory
	}

	func getFloat64() -> Float64 {
		UnsafeMutablePointer<UInt64>(_bits).memory = getUInt64()
		return UnsafePointer<Float64>(_bits).memory
	}

	func getInt8(count: Int) -> Array<Int8> {
		return getArray(count, defaultValue: 0) { self.getInt8() }
	}

	func getInt16(count: Int) -> Array<Int16> {
		return getArray(count, defaultValue: 0) { self.getInt16() }
	}

	func getInt32(count: Int) -> Array<Int32> {
		return getArray(count, defaultValue: 0) { self.getInt32() }
	}

	func getInt64(count: Int) -> Array<Int64> {
		return getArray(count, defaultValue: 0) { self.getInt64() }
	}

	func getUInt8(count: Int) -> Array<UInt8> {
		return getArray(count, defaultValue: 0) { self.getUInt8() }
	}

	func getUInt16(count: Int) -> Array<UInt16> {
		return getArray(count, defaultValue: 0) { self.getUInt16() }
	}

	func getUInt32(count: Int) -> Array<UInt32> {
		return getArray(count, defaultValue: 0) { self.getUInt32() }
	}

	func getUInt64(count: Int) -> Array<UInt64> {
		return getArray(count, defaultValue: 0) { self.getUInt64() }
	}

	func getFloat32(count: Int) -> Array<Float32> {
		return getArray(count, defaultValue: 0.0) { self.getFloat32() }
	}

	func getFloat64(count: Int) -> Array<Float64> {
		return getArray(count, defaultValue: 0.0) { self.getFloat64() }
	}

	func getUTF8(length: Int) -> String {
		return decodeCodeUnits(getUInt8(length), codec: UTF8())
	}

	func getTerminatedUTF8(terminator: UInt8 = 0) -> String {
		return decodeCodeUnits(getTerminatedUInt8(terminator), codec: UTF8())
	}

	func decodeCodeUnits<C : UnicodeCodecType>(codeUnits: Array<C.CodeUnit>, var codec: C) -> String {
		var generator = codeUnits.generate()
		var characters = Array<Character>()
		characters.reserveCapacity(codeUnits.count)
		var done = false

		while (!done) {
			switch codec.decode(&generator) {
			case .Result(let scalar):
				characters.append(Character(scalar))

			case .EmptyInput:
				done = true

			case .Error:
				done = true
			}
		}

		var string = String()
		string.reserveCapacity(characters.count)
		string.extend(characters)
		
		return string
	}


	func getArray<T>(count: Int, defaultValue: T, getter: () -> T) -> Array<T> {
		var array = Array<T>(count: count, repeatedValue: defaultValue)
		for index in 0..<count { array[index] = getter() }
		return array
	}

	func getArray<T>(count: Int, getter: () -> T) -> Array<T> {
		var array = Array<T>()
		array.reserveCapacity(count)
		for index in 0..<count { array.append(getter()) }
		return array
	}

	func getTerminatedUInt8(terminator: UInt8) -> Array<UInt8> {
		return getArray(terminator) { self.getUInt8() }
	}

	func getArray<T : Equatable>(terminator: T, getter: () -> T) -> Array<T> {
		var array = Array<T>()
		var done = false

		while (!done) {
			let value = getter()

			if (value == terminator) {
				done = true
			} else {
				array.append(value)
			}
		}

		return array
	}

	func getBits<T>() -> T {

		// FIXME: This will explode

		let bytes = UnsafePointer<UInt8>(_data.bytes)
		for index in 0..<sizeof(T) {
			_bits[index] = bytes[position++]
		}

		return UnsafePointer<T>(_bits).memory
	}

	// MARK: Writing

	func putInt8(value: Int8) {
		putUInt8(UInt8(bitPattern: value))
	}

	func putInt16(value: Int16) {
		putUInt16(UInt16(bitPattern: value))
	}

	func putInt32(value: Int32) {
		putUInt32(UInt32(bitPattern: value))
	}

	func putInt64(value: Int64) {
		putUInt64(UInt64(bitPattern: value))
	}

	func putUInt8(value: UInt8) {
		_data.increaseLengthBy(sizeof(UInt8))
		var bytes = UnsafeMutablePointer<UInt8>(_data.mutableBytes)
		bytes[position++] = value
	}

	func putUInt16(value: UInt16) {
		putBits(_order.fromNative(value))
	}

	func putUInt32(value: UInt32) {
		putBits(_order.fromNative(value))
	}

	func putUInt64(value: UInt64) {
		putBits(_order.fromNative(value))
	}

	func putFloat32(value: Float32) {
		UnsafeMutablePointer<Float32>(_bits).memory = value
		putUInt32(UnsafePointer<UInt32>(_bits).memory)
	}

	func putFloat64(value: Float64) {
		UnsafeMutablePointer<Float64>(_bits).memory = value
		putUInt64(UnsafePointer<UInt64>(_bits).memory)
	}

	func putUTF8(value: String) {
		putArray(value.utf8) { self.putUInt8($0) }
	}

	func putInt8(values: Array<Int8>) {
		putArray(values) { self.putInt8($0) }
	}

	func putInt16(values: Array<Int16>) {
		putArray(values) { self.putInt16($0) }
	}

	func putInt32(values: Array<Int32>) {
		putArray(values) { self.putInt32($0) }
	}

	func putInt64(values: Array<Int64>) {
		putArray(values) { self.putInt64($0) }
	}

	func putUInt8(source: Array<UInt8>) {
		_data.increaseLengthBy(sizeof(UInt8) * source.count )

		var bytes = UnsafeMutablePointer<UInt8>(_data.mutableBytes)
		for v in source {
			bytes[position++] = v
		}
	}

	func putUInt16(values: Array<UInt16>) {
		putArray(values) { self.putUInt16($0) }
	}

	func putUInt32(values: Array<UInt32>) {
		putArray(values) { self.putUInt32($0) }
	}

	func putUInt64(values: Array<UInt64>) {
		putArray(values) { self.putUInt64($0) }
	}

	func putFloat32(values: Array<Float32>) {
		putArray(values) { self.putFloat32($0) }
	}

	func putFloat64(values: Array<Float64>) {
		putArray(values) { self.putFloat64($0) }
	}

	func putTerminatedUTF8(value: String, terminator: UInt8 = 0) {
		putUTF8(value)
		putUInt8(terminator)
	}

	func putArray<S : SequenceType>(values: S, putter: (S.Generator.Element) -> ()) {
		for value in values {
			putter(value)
		}
	}

	func putBits<T>(value: T) {
		UnsafeMutablePointer<T>(_bits).memory = value

		_data.increaseLengthBy(sizeof(T))
		var bytes = UnsafeMutablePointer<UInt8>(_data.mutableBytes)
		for index in 0..<sizeof(T) {
			bytes[position++] = _bits[index]
		}
	}
}