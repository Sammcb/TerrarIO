//
//  TerrariaWorldReader.swift
//  TerrarIO
//
//  Created by Sam McBroom on 8/23/23.
//

import Foundation

protocol WorldReader {}

extension WorldReader {
	static func readRawString<T: BinaryInteger>(size length: T, from offset: Int, in data: Data) -> (Int, String) {
		let stringOffset = offset + Int(length)
		let stringData = data[offset ..< stringOffset]
		let string = String(data: stringData, encoding: .ascii) ?? ""
		return (stringOffset, string)
	}

	static func readValue<T>(from offset: Int, in data: Data) -> (Int, T) {
		let typeSize = MemoryLayout<T>.size
		let value = data.withUnsafeBytes({ $0.loadUnaligned(fromByteOffset: offset, as: T.self) })
		return (offset + typeSize, value)
	}

	static func readValue(from offset: Int, in data: Data) -> (Int, String) {
		let read: (offset: Int, stringLength: UInt8) = readValue(from: offset, in: data)
		let readString: (offset: Int, value: String) = readRawString(size: read.stringLength, from: read.offset, in: data)
		return (readString.offset, readString.value)
	}

	static func readValue<T: BinaryInteger>(with dataType: T.Type = UInt8.self, from offset: Int, in data: Data) -> (Int, Bool) {
		let read: (offset: Int, value: T) = readValue(from: offset, in: data)
		return (read.offset, read.value > 0)
	}

	static func readValues<T, U: BinaryInteger & Strideable<V>, V: SignedInteger>(length: U, from offset: Int, in data: Data) -> (Int, [T]) {
		var read: (offset: Int, value: T) = readValue(from: offset, in: data)
		var values = [read.value]
		for _ in 0 ..< length - 1 {
			read = readValue(from: read.offset, in: data)
			values.append(read.value)
		}
		return (read.offset, values)
	}
	
	static func readBitList(length: Int, from listOffset: Int, in data: Data) -> (Int, [Bool]) {
		let byteSize = UInt8.bitWidth
		var offset = listOffset
		var bits: [Bool] = []
		for _ in stride(from: 0, to: length, by: byteSize) {
			let byte: UInt8
			(offset, byte) = readValue(from: offset, in: data)
			var bitMask: UInt8 = 0b1
			for _ in 0 ..< byteSize {
				let bit = byte & bitMask > 0
				bits.append(bit)
				bitMask = bitMask << 1
				guard bits.count < length else {
					break
				}
			}
		}
		return (offset, bits)
	}
}
