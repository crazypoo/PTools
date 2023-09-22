/*
 * IPv4.swift
 * SimpleSwiftPing
 *
 * Created by François Lamboley on 13/06/2018.
 * Copyright © 2018 Frizlab. All rights reserved.
 */

import Foundation
/** Describes the on-the-wire header format for an IPv4 packet.

This defines the header structure of IPv4 packets on the wire. We need this in
order to skip this header in the IPv4 case, where the kernel passes it to us for
no obvious reason. */
struct IPv4Header {
	
	static let size = 20
	
	struct Address {
		
		let byte1: UInt8
		let byte2: UInt8
		let byte3: UInt8
		let byte4: UInt8
		
		init() {
			byte1 = 0
			byte2 = 0
			byte3 = 0
			byte4 = 0
		}
		
		init(dataPointer: inout UnsafePointer<UInt8>) {
			byte1 = dataPointer.pointee; dataPointer = dataPointer.advanced(by: 1)
			byte2 = dataPointer.pointee; dataPointer = dataPointer.advanced(by: 1)
			byte3 = dataPointer.pointee; dataPointer = dataPointer.advanced(by: 1)
			byte4 = dataPointer.pointee; dataPointer = dataPointer.advanced(by: 1)
		}
		
	}
	
	let versionAndHeaderLength: UInt8
	let differentiatedServices: UInt8
	let totalLength: UInt16
	let identification: UInt16
	let flagsAndFragmentOffset: UInt16
	let timeToLive: UInt8
	let `protocol`: UInt8
	let headerChecksum: UInt16
	let sourceAddress: Address
	let destinationAddress: Address
	/* options... */
	/* data... */
	
	init(data: Data) {
		assert(data.count >= IPv4Header.size)
		
		var versionAndHeaderLengthI: UInt8 = 0
		var differentiatedServicesI: UInt8 = 0
		var totalLengthI: UInt16 = 0
		var identificationI: UInt16 = 0
		var flagsAndFragmentOffsetI: UInt16 = 0
		var timeToLiveI: UInt8 = 0
		var protocolI: UInt8 = 0
		var headerChecksumI: UInt16 = 0
		var sourceAddressI = Address()
		var destinationAddressI = Address()
		data.withUnsafeBytes{ (bytes: UnsafePointer<UInt8>) in
			var curPosUInt8 = bytes
			versionAndHeaderLengthI = curPosUInt8.pointee; curPosUInt8 = curPosUInt8.advanced(by: 1)
			differentiatedServicesI = curPosUInt8.pointee; curPosUInt8 = curPosUInt8.advanced(by: 1)
			
			var curPosUInt16 = UnsafePointer<UInt16>(OpaquePointer(curPosUInt8))
			totalLengthI = curPosUInt16.pointee;            curPosUInt16 = curPosUInt16.advanced(by: 1)
			identificationI = curPosUInt16.pointee;         curPosUInt16 = curPosUInt16.advanced(by: 1)
			flagsAndFragmentOffsetI = curPosUInt16.pointee; curPosUInt16 = curPosUInt16.advanced(by: 1)
			
			curPosUInt8 = UnsafePointer<UInt8>(OpaquePointer(curPosUInt16))
			timeToLiveI = curPosUInt8.pointee; curPosUInt8 = curPosUInt8.advanced(by: 1)
			protocolI = curPosUInt8.pointee;   curPosUInt8 = curPosUInt8.advanced(by: 1)
			
			curPosUInt16 = UnsafePointer<UInt16>(OpaquePointer(curPosUInt8))
			headerChecksumI = curPosUInt16.pointee; curPosUInt16 = curPosUInt16.advanced(by: 1)
			
			curPosUInt8 = UnsafePointer<UInt8>(OpaquePointer(curPosUInt16))
			sourceAddressI = Address(dataPointer: &curPosUInt8)
			destinationAddressI = Address(dataPointer: &curPosUInt8)
		}
		
		versionAndHeaderLength = versionAndHeaderLengthI
		differentiatedServices = differentiatedServicesI
		totalLength = totalLengthI
		identification = identificationI
		flagsAndFragmentOffset = flagsAndFragmentOffsetI
		timeToLive = timeToLiveI
		`protocol` = protocolI
		headerChecksum = headerChecksumI
		sourceAddress = sourceAddressI
		destinationAddress = destinationAddressI
	}
	
}
