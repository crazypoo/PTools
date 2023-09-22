/*
 * ICMP.swift
 * SimpleSwiftPing
 *
 * Created by François Lamboley on 13/06/2018.
 * Copyright © 2018 Frizlab. All rights reserved.
 */

import Foundation

public enum ICMPv4TypeEcho : UInt8 {
	
	/** The ICMP `type` for a ping request; in this case `code` is always 0. */
	case request = 8
	/** The ICMP `type` for a ping response; in this case `code` is always 0. */
	case reply   = 0
	
}


public enum ICMPv6TypeEcho : UInt8 {
	
	/** The ICMP `type` for a ping request; in this case `code` is always 0. */
	case request = 128
	/** The ICMP `type` for a ping response; in this case `code` is always 0. */
	case reply   = 129
	
}



/* If we could force C-based struct layout, this would be the struct definition
 * we would have for an ICMP header. With the current state of Swift, this is
 * **not** possible. Do **NOT** dump the ICMPHeader struct on the wire expecting
 * things to go great! They might, but we have no guarantee they will…
 *
 * Because we won't/can't dump the struct on the wire, all of the values have
 * the endianness of the host. The conversion is done directly when initing the
 * struct from the data or retrieving the header data. */
public struct ICMPHeader {
	
	public static let size = 8
	public static let checksumDelta = 2
	
	public var type: UInt8 {didSet {headerBytes[0] = type}}
	public var code: UInt8 {didSet {headerBytes[1] = type}}
	public var checksum: UInt16       {didSet {headerBytes[2...].withUnsafeMutableBytes{ (bytes: UnsafeMutablePointer<UInt16>) in bytes.pointee = checksum.bigEndian }}}
	public var identifier: UInt16     {didSet {headerBytes[4...].withUnsafeMutableBytes{ (bytes: UnsafeMutablePointer<UInt16>) in bytes.pointee = identifier.bigEndian }}}
	public var sequenceNumber: UInt16 {didSet {headerBytes[6...].withUnsafeMutableBytes{ (bytes: UnsafeMutablePointer<UInt16>) in bytes.pointee = sequenceNumber.bigEndian }}}
	/* data... */
	
	public private(set) var headerBytes: Data
	
	public init(type t: UInt8, code c: UInt8, checksum chk: UInt16, identifier i: UInt16, sequenceNumber n: UInt16) {
		type = t
		code = c
		checksum = chk
		identifier = i
		sequenceNumber = n
		
		headerBytes = Data(count: ICMPHeader.size)
		headerBytes.withUnsafeMutableBytes{ (bytes: UnsafeMutablePointer<UInt8>) in
			var curPosUInt8 = bytes
			curPosUInt8.pointee = type; curPosUInt8 = curPosUInt8.advanced(by: 1)
			curPosUInt8.pointee = code; curPosUInt8 = curPosUInt8.advanced(by: 1)
			
			var curPosUInt16 = UnsafeMutablePointer<UInt16>(OpaquePointer(curPosUInt8))
			curPosUInt16.pointee = checksum.bigEndian; curPosUInt16 = curPosUInt16.advanced(by: 1)
			curPosUInt16.pointee = identifier.bigEndian; curPosUInt16 = curPosUInt16.advanced(by: 1)
			curPosUInt16.pointee = sequenceNumber.bigEndian; curPosUInt16 = curPosUInt16.advanced(by: 1)
		}
	}
	
	public init(data: Data) {
		assert(data.count >= ICMPHeader.size)
		
		var typeI: UInt8 = 0
		var codeI: UInt8 = 0
		var checksumI: UInt16 = 0
		var identifierI: UInt16 = 0
		var sequenceNumberI: UInt16 = 0
		data.withUnsafeBytes{ (bytes: UnsafePointer<UInt8>) in
			var curPosUInt8 = bytes
			typeI = curPosUInt8.pointee; curPosUInt8 = curPosUInt8.advanced(by: 1)
			codeI = curPosUInt8.pointee; curPosUInt8 = curPosUInt8.advanced(by: 1)
			
			/* Note: UInt16(bigEndian:) <=> CFSwapInt16BigToHost() */
			var curPosUInt16 = UnsafePointer<UInt16>(OpaquePointer(curPosUInt8))
			checksumI = UInt16(bigEndian: curPosUInt16.pointee); curPosUInt16 = curPosUInt16.advanced(by: 1)
			identifierI = UInt16(bigEndian: curPosUInt16.pointee); curPosUInt16 = curPosUInt16.advanced(by: 1)
			sequenceNumberI = UInt16(bigEndian: curPosUInt16.pointee); curPosUInt16 = curPosUInt16.advanced(by: 1)
		}
		
		type = typeI
		code = codeI
		checksum = checksumI
		identifier = identifierI
		sequenceNumber = sequenceNumberI
		
		headerBytes = Data(data[..<ICMPHeader.size])
	}
	
}

//__Check_Compile_Time(sizeof(ICMPHeader) == 8);
//__Check_Compile_Time(offsetof(ICMPHeader, type) == 0);
//__Check_Compile_Time(offsetof(ICMPHeader, code) == 1);
//__Check_Compile_Time(offsetof(ICMPHeader, checksum) == 2);
//__Check_Compile_Time(offsetof(ICMPHeader, identifier) == 4);
//__Check_Compile_Time(offsetof(ICMPHeader, sequenceNumber) == 6);
