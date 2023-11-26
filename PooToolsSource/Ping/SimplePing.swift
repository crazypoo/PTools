/*
 * SimplePing.swift
 * SimpleSwiftPing
 *
 * Created by François Lamboley on 12/06/2018.
 * Copyright © 2018 Frizlab. All rights reserved.
 */

import CFNetwork
import Foundation

public enum AddressStyle {
    case any    /* Use the first IPv4 or IPv6 address found (default). */
    case icmpV4 /* Use the first IPv4 address found. */
    case icmpV6 /* Use the first IPv6 address found. */
}

public protocol SimplePingDelegate : AnyObject {
    
    /** A SimplePing delegate callback, called once the object has started up.
    This is called shortly after you start the object to tell you that the object
    has successfully started. On receiving this callback, you can call
    `-sendPingWithData:` to send pings.
    
    If the object didn't start, `-simplePing:didFailWithError:` is called
    instead.
    
    - parameter pinger: The object issuing the callback.
    - parameter address: The address that's being pinged; at the time this
    delegate callback is made, this will have the same value as the `hostAddress`
    property. */
    func simplePing(_ pinger: SimplePing, didStart address: Data)
    
    /** A SimplePing delegate callback, called if the object fails to start up.
    
    This is called shortly after you start the object to tell you that the object
    has failed to start. The most likely cause of failure is a problem resolving
    `hostName`.
    
    By the time this callback is called, the object has stopped (that is, you
    don’t need to call `-stop` yourself).
    
    - parameter pinger: The object issuing the callback.
    - parameter error: Describes the failure. */
    func simplePing(_ pinger: SimplePing, didFail error: Error)
    
    /** A SimplePing delegate callback, called when the object has successfully
    sent a ping packet.
    
    Each call to `-sendPingWithData:` will result in either a
    `-simplePing:didSendPacket:sequenceNumber:` delegate callback or a
    `-simplePing:didFailToSendPacket:sequenceNumber:error:` delegate callback
    (unless you stop the object before you get the callback). These callbacks are
    currently delivered synchronously from within `-sendPingWithData:`, but this
    synchronous behaviour is not considered API.
    
    - parameter pinger: The object issuing the callback.
    - parameter packet: The packet that was sent; this includes the ICMP header
    (`ICMPHeader`) and the data you passed to `-sendPingWithData:` but does not
    include any IP-level headers.
    - parameter sequenceNumber: The ICMP sequence number of that packet. */
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16)
    
    /** A SimplePing delegate callback, called when the object fails to send a
    ping packet.
    
    Each call to `-sendPingWithData:` will result in either a
    `-simplePing:didSendPacket:sequenceNumber:` delegate callback or a
    `-simplePing:didFailToSendPacket:sequenceNumber:error:` delegate callback
    (unless you stop the object before you get the callback). These callbacks are
    currently delivered synchronously from within `-sendPingWithData:`, but this
    synchronous behaviour is not considered API.
    
    - parameter pinger: The object issuing the callback.
    - parameter packet: The packet that was not sent; see
    `-simplePing:didSendPacket:sequenceNumber:` for details.
    - parameter sequenceNumber: The ICMP sequence number of that packet.
    - parameter error: Describes the failure. */
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error)
    
    /** A SimplePing delegate callback, called when the object receives a ping
    response.
    
    If the object receives an ping response that matches a ping request that it
    sent, it informs the delegate via this callback.  Matching is primarily done
    based on the ICMP identifier, although other criteria are used as well.
    
    - parameter pinger: The object issuing the callback.
    - parameter packet: The packet received; this includes the ICMP header
    (`ICMPHeader`) and any data that follows that in the ICMP message but does
    not include any IP-level headers.
    - parameter sequenceNumber: The ICMP sequence number of that packet. */
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16)
    
    /** A SimplePing delegate callback, called when the object receives an
    unmatched ICMP message.
    
    If the object receives an ICMP message that does not match a ping request
    that it sent, it informs the delegate via this callback. The nature of ICMP
    handling in a BSD kernel makes this a common event because, when an ICMP
    message arrives, it is delivered to all ICMP sockets.
    
    - important: This callback is especially common when using IPv6 because IPv6
    uses ICMP for important network management functions. For example, IPv6
    routers periodically send out Router Advertisement (RA) packets via Neighbor
    Discovery Protocol (NDP), which is implemented on top of ICMP.
    
    For more on matching, see the discussion associated with
    `-simplePing:didReceivePingResponsePacket:sequenceNumber:`.
    
    - parameter pinger: The object issuing the callback.
    - parameter packet: The packet received; this includes the ICMP header
    (`ICMPHeader`) and any data that follows that in the ICMP message but does
    not include any IP-level headers. */
    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data)
}

public class SimplePing {
		
	public let hostName: String
	/** The IP address version to use. Should be set before starting the ping. */
	public var addressStyle: AddressStyle
	
	public weak var delegate: SimplePingDelegate?
	
	/** The identifier used by pings by this object.
	
	When you create an instance of this object it generates a random identifier
	that it uses to identify its own pings. */
	public let identifier: UInt16
	
	/** The address being pinged.
	
	The contents of the Data is a (struct sockaddr) of some form. The value is
	nil while the object is stopped and remains nil on start until
	`-simplePing:didStartWithAddress:` is called. */
	public private(set) var hostAddress: Data?
	/** The address family for `hostAddress`, or `AF_UNSPEC` if that’s nil. */
	public var hostAddressFamily: sa_family_t {
		guard let hostAddress = hostAddress, hostAddress.count >= MemoryLayout<sockaddr>.size else {
			return sa_family_t(AF_UNSPEC)
		}
        return hostAddress.withUnsafeBytes { (rawBufferPointer) -> sa_family_t in
            if let pointer = rawBufferPointer.baseAddress?.assumingMemoryBound(to: sockaddr.self) {
                return pointer.pointee.sa_family
            }
            return 0 // 这是一个默认值，可以根据需要进行调整
        }
	}
	
	/** The next sequence number to be used by this object.
	
	This value starts at zero and increments each time you send a ping (safely
	wrapping back to zero if necessary). The sequence number is included in the
	ping, allowing you to match up requests and responses, and thus calculate
	ping times and so on. */
	public private(set) var nextSequenceNumber: UInt16 = 0
	
	/** Initialise the object to ping the specified host.
	
	- parameter hostName: The DNS name of the host to ping; an IPv4 or IPv6
	address in string form will work here.
	- returns: The initialised object. */
	public init(hostName hn: String, addressStyle s: AddressStyle = .any) {
		hostName = hn
		addressStyle = s
		identifier = UInt16.random(in: .min ... .max)
	}
	
	deinit {
		stop()
	}
	
	/** Starts the object.
	
	You should set up the delegate and any ping parameters before calling this.
	
	If things go well you'll soon get the `-simplePing:didStartWithAddress:`
	delegate callback, at which point you can start sending pings (via
	`-sendPingWithData:`) and will start receiving ICMP packets (either ping
	responses, via the `-simplePing:didReceivePingResponsePacket:sequenceNumber:`
	delegate callback, or unsolicited ICMP packets, via the
	`-simplePing:didReceiveUnexpectedPacket:` delegate callback).
	
	If the object fails to start, typically because `hostName` doesn't resolve,
	you'll get the `-simplePing:didFailWithError:` delegate callback.
	
	It is not correct to start an already started object. */
	public func start() {
		assert(host == nil)
		assert(hostAddress == nil)
		
		var context = CFHostClientContext(version: 0, info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self), retain: nil, release: nil, copyDescription: nil)
		let h = CFHostCreateWithName(nil, hostName as CFString).autorelease().takeUnretainedValue()
		host = h
		
		CFHostSetClient(h, hostResolveCallback, &context)
		
		CFHostScheduleWithRunLoop(h, CFRunLoopGetCurrent(), RunLoop.Mode.default.rawValue as CFString)
		
		var error = CFStreamError()
		if !CFHostStartInfoResolution(h, CFHostInfoType.addresses, &error) {
			didFail(hostStreamError: error)
		}
	}
	
	/** Sends a ping packet containing the specified data.
	
	The object must be started when you call this method and, on starting the
	object, you must wait for the `-simplePing:didStartWithAddress:` delegate
	callback before calling it.
	
	- parameter data: Some data to include in the ping packet, after the ICMP
	header, or nil if you want the packet to include a standard 56 byte payload
	(resulting in a standard 64 byte ping). */
	public func sendPing(data: Data?) {
		guard let hostAddress = hostAddress else {fatalError("Gotta wait for -simplePing:didStartWithAddress: before sending a ping")}
		
		/* *** Construct the ping packet. *** */
		
		/* Our dummy payload is sized so that the resulting ICMP packet, including
		 * the ICMPHeader, is 64-bytes, which makes it easier to recognise our
		 * packets on the wire. */
		let payload = data ?? String(format: "%28zd bottles of beer on the wall", 99 - (nextSequenceNumber % 100)).data(using: .ascii)!
		assert(data != nil || payload.count == 56)
		
		let packet: Data
		switch hostAddressFamily {
		case sa_family_t(AF_INET):
			packet = pingPacket(type: ICMPv4TypeEcho.request.rawValue, payload: payload, requiresChecksum: true)
			
		case sa_family_t(AF_INET6):
			packet = pingPacket(type: ICMPv6TypeEcho.request.rawValue, payload: payload, requiresChecksum: true)
			
		default:
			fatalError()
		}
		
		/* *** Send the packet. *** */
		
		let err: Int32
		var bytesSent: Int
		if let socket = sock {
            bytesSent = packet.withUnsafeBytes { (packetBytes: UnsafeRawBufferPointer) -> Int in
                hostAddress.withUnsafeBytes { (hostAddressBytes: UnsafeRawBufferPointer) -> Int in
                    let result = sendto(
                        CFSocketGetNative(socket),
                        packetBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        packet.count,
                        0, /* flags */
                        hostAddressBytes.baseAddress?.assumingMemoryBound(to: sockaddr.self),
                        socklen_t(hostAddress.count)
                    )
                    return result
                }
            }
            
            if bytesSent >= 0 {
                err = 0
            } else {
                err = errno
            }
		} else {
			bytesSent = -1
			err = EBADF
		}
		
		/* *** Handle the results of the send. *** */
		
		if bytesSent > 0 && bytesSent == packet.count {
			/* Complete success. Tell the client. */
			delegate?.simplePing(self, didSendPacket: packet, sequenceNumber: nextSequenceNumber)
		} else {
			/* Some sort of failure. Tell the client. */
			let error = NSError(domain: NSPOSIXErrorDomain, code: Int(err != 0 ? err : ENOBUFS), userInfo: nil)
			delegate?.simplePing(self, didFailToSendPacket: packet, sequenceNumber: nextSequenceNumber, error: error)
		}
		
		nextSequenceNumber &+= 1
		if nextSequenceNumber == 0 {
			nextSequenceNumberHasWrapped = true
		}
	}
	
	/** Stops the object.
	
	You should call this when you're done pinging.
	It is safe to call this on an object that's stopped. */
	public func stop() {
		stopHostResolution()
		stopSocket()
		
		/* Junk the host address on stop. If the client calls -start again, we’ll
		 * re-resolve the host name. */
		
		hostAddress = nil
	}
	
	/* ***************
      MARK: - Private
	   *************** */
	
	/** Returns the **big-endian representation** of the checksum of the packet. */
	static private func packetChecksum(packetData: Data) -> UInt16 {
		var sum: Int32 = 0
		var packetData = packetData
		
		/* Mop up an odd byte, if necessary */
		if packetData.count % 2 == 1 {
			packetData += Data([0])
		}
		
		/* Our algorithm is simple, using a 32 bit accumulator (sum), we
		 * add sequential 16 bit words to it, and at the end, fold back all the
		 * carry bits from the top 16 bits into the lower 16 bits. */
        packetData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            var curPos = bytes.baseAddress?.assumingMemoryBound(to: UInt16.self)
            assert(packetData.count % 2 == 0)
            for i in 0..<(packetData.count / 2) {
                if i != ICMPHeader.checksumDelta / 2 {
                    sum &+= Int32(curPos?.pointee ?? 0)
                }
                curPos = curPos?.advanced(by: 1)
            }
        }
		
		/* Add back carry outs from top 16 bits to low 16 bits */
		sum   = (sum >> 16) &+ (sum & 0xffff)            /* add hi 16 to low 16 */
		sum &+= (sum >> 16)                              /* add carry */
		return UInt16(truncating: NSNumber(value: ~sum)) /* truncate to 16 bits */
	}
	
	/** Calculates the offset of the ICMP header within an IPv4 packet.
	
	In the IPv4 case the kernel returns us a buffer that includes the IPv4
	header. We're not interested in that, so we have to skip over it. This code
	does a rough check of the IPv4 header and, if it looks OK, returns the offset
	of the ICMP header.
	
	- parameter packet: The IPv4 packet, as returned to us by the kernel.
	- returns: The offset of the ICMP header, or nil. */
	static private func icmpHeaderOffset(in ipv4Packet: Data) -> Int? {
		guard ipv4Packet.count >= IPv4Header.size + ICMPHeader.size else {return nil}
		
		let ipv4Header = IPv4Header(data: ipv4Packet)
		if ipv4Header.versionAndHeaderLength & 0xF0 == 0x40 /* IPv4 */ && Int32(ipv4Header.protocol) == IPPROTO_ICMP {
			let ipHeaderLength = Int(ipv4Header.versionAndHeaderLength & 0x0F) * MemoryLayout<UInt32>.size
			if ipv4Packet.count >= (ipHeaderLength + ICMPHeader.size) {
				return ipHeaderLength
			}
		}
		return nil
	}
	
	fileprivate var host: CFHost?
	fileprivate var sock: CFSocket?
	
	/** True if nextSequenceNumber has wrapped from 65535 to 0. */
	private var nextSequenceNumberHasWrapped = false
	
	private func didFail(error: Error) {
		delegate?.simplePing(self, didFail: error)
		
		/* Below is more or less the direct translation from ObjC to Swift of the
		 * original project. I simplified a bit as I think most of the protections
		 * are not needed anymore.
		
		--------------
		
		/* We retain ourselves temporarily because it's common for the delegate
		 * method to release its last reference to us, which causes -dealloc to be
		 * called here.
		 * If we then reference self on the return path, things go badly. I don't
		 * think that happens currently, but I've got into the habit of doing this
		 * as a defensive measure. */
		let strongSelf = self
		let strongDelegate = strongSelf.delegate
		
		strongSelf.stop()
		strongDelegate?.simplePing(self, didFail: error) */
	}
	
	fileprivate func didFail(hostStreamError streamError: CFStreamError) {
		let userInfo: [String: Any]?
		
		switch streamError.domain {
		case CFIndex(kCFStreamErrorDomainNetDB): userInfo = [kCFGetAddrInfoFailureKey as String: streamError.error]
		default:                                 userInfo = nil
		}
		
		didFail(error: NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue), userInfo: userInfo))
	}
	
	private func pingPacket(type: UInt8, payload: Data, requiresChecksum: Bool) -> Data {
		let header = ICMPHeader(
			type: type, code: 0, checksum: 0,
			identifier: identifier, sequenceNumber: nextSequenceNumber
		)
		
		var packet = header.headerBytes + payload
		if requiresChecksum {
			/* The IP checksum routine returns a 16-bit number that's already in
			 * correct byte order (due to wacky 1's complement maths), so we just
			 * put it into the packet as a 16-bit unit. */
			let checksumBig = SimplePing.packetChecksum(packetData: packet)
            packet[ICMPHeader.checksumDelta...].withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
                if let curPos = bytes.baseAddress?.assumingMemoryBound(to: UInt16.self) {
                    curPos.pointee = checksumBig
                }
            }
		}
		
		return packet
	}
	
	/** Checks whether the specified sequence number is one we sent.
	
	- parameter sequenceNumber: The incoming sequence number.
	- returns: `true` if the sequence number looks like one we sent. */
	private func validateSequenceNumber(_ sequenceNumber: UInt16) -> Bool {
		if nextSequenceNumberHasWrapped {
			/* If the sequence numbers have wrapped that we can't reliably check
			 * whether this is a sequence number we sent.  Rather, we check to see
			 * whether the sequence number is within the last 120 sequence numbers
			 * we sent. Note that the UInt16 subtraction here does the right thing
			 * regardless of the wrapping.
			 *
			 * Why 120? Well, if we send one ping per second, 120 is 2 minutes,
			 * which is the standard “max time a packet can bounce around the
			 * Internet” value. */
			return (nextSequenceNumber &- sequenceNumber) < 120
		} else {
			return sequenceNumber < nextSequenceNumber
		}
	}
	
	/** Checks whether an incoming IPv4 packet looks like a ping response.
	
	This routine can modify the `packet` data. If the packet is validated, it
	removes the IPv4 header from the front of the packet.
	
	- parameter packet: The IPv4 packet, as returned to us by the kernel.
	- parameter sequenceNumber: A pointer to a place to start the ICMP sequence
	number.
	- returns: true if the packet looks like a reasonable IPv4 ping response. */
	private func validatePing4ResponsePacket(_ packet: inout Data, sequenceNumber: inout UInt16) -> Bool {
		guard let icmpHeaderOffset = SimplePing.icmpHeaderOffset(in: packet) else {
			return false
		}
		
		/* Note: We crash when we don’t copy the slice content; not sure why… (Xcode 10.0 beta (10L176w)) */
		let icmpPacket = Data(packet[icmpHeaderOffset...])
        let icmpHeader = ICMPHeader(data: icmpPacket)
		
		let receivedChecksum = icmpHeader.checksum
		let calculatedChecksum = UInt16(bigEndian: SimplePing.packetChecksum(packetData: icmpPacket)) /* The checksum method returns a big-endian UInt16 */
		guard receivedChecksum == calculatedChecksum else {return false}
		
		guard icmpHeader.type == ICMPv4TypeEcho.reply.rawValue && icmpHeader.code == 0 else {return false}
		guard icmpHeader.identifier == identifier else {return false}
		
		guard validateSequenceNumber(icmpHeader.sequenceNumber) else {return false}
		
		/* Remove the IPv4 header off the front of the data we received, leaving
		 * us with just the ICMP header and the ping payload. */
		packet = icmpPacket
		sequenceNumber = icmpHeader.sequenceNumber
		
		return true
	}
	
	/** Checks whether an incoming IPv6 packet looks like a ping response.
	
	- parameter packet: The IPv6 packet, as returned to us by the kernel; note
	that this routine could modify this data but does not need to in the IPv6
	case.
	- parameter sequenceNumber: A pointer to a place to start the ICMP sequence
	number.
	- returns: true if the packet looks like a reasonable IPv4 ping response. */
	private func validatePing6ResponsePacket(_ packet: inout Data, sequenceNumber: inout UInt16) -> Bool {
		guard packet.count >= ICMPHeader.size else {return false}
		
		let icmpHeader = ICMPHeader(data: packet)
		
		/* In the IPv6 case we don't check the checksum because that’s hard (we
		 * need to cook up an IPv6 pseudo header and we don’t have the
		 * ingredients) and unnecessary (the kernel has already done this check). */
		
		guard icmpHeader.type == ICMPv6TypeEcho.reply.rawValue && icmpHeader.code == 0 else {return false}
		guard icmpHeader.identifier == identifier else {return false}
		
		guard validateSequenceNumber(icmpHeader.sequenceNumber) else {return false}
		
		sequenceNumber = icmpHeader.sequenceNumber
		
		return true
	}
	
	/** Checks whether an incoming packet looks like a ping response.
	
	- parameter packet: The packet, as returned to us by the kernel; note that
	we may end up modifying this data.
	- parameter sequenceNumber: A pointer to a place to start the ICMP sequence
	number.
	- returns: true if the packet looks like a reasonable IPv4 ping response. */
	private func validatePingResponsePacket(_ packet: inout Data, sequenceNumber: inout UInt16) -> Bool {
		switch hostAddressFamily {
		case sa_family_t(AF_INET):  return validatePing4ResponsePacket(&packet, sequenceNumber: &sequenceNumber)
		case sa_family_t(AF_INET6): return validatePing6ResponsePacket(&packet, sequenceNumber: &sequenceNumber)
		default: fatalError()
		}
	}
	
	/** Reads data from the ICMP socket.
	
	Called by the socket handling code (SocketReadCallback) to process an ICMP
	message waiting on the socket. */
	fileprivate func readData() {
		/* 65535 is the maximum IP packet size, which seems like a reasonable bound
		 * here (plus it's what <x-man-page://8/ping> uses). */
		let bufferSize = 65535
		let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 0 /* We don’t need a specific alignment AFAICT */)
		defer {buffer.deallocate()}
		
		/* Actually read the data. We use recvfrom(), and thus get back the source
		 * address, but we don’t actually do anything with it. It would be trivial
		 * to pass it to the delegate but we don’t need it in this example. */
		let err: Int32
		var addr = sockaddr_storage()
    	var addrLen = socklen_t(MemoryLayout<sockaddr_storage>.size)
		let bytesRead = withUnsafeMutablePointer(to: &addr, { (addrStoragePtr: UnsafeMutablePointer<sockaddr_storage>) -> Int in
			let addrPtr = UnsafeMutablePointer<sockaddr>(OpaquePointer(addrStoragePtr))
			return recvfrom(CFSocketGetNative(sock), buffer, bufferSize, 0 /* flags */, addrPtr, &addrLen)
		})
		if bytesRead >= 0 {err = 0}
		else              {err = errno}
		
		/* *** Process the data we read. *** */
		
		if bytesRead > 0 {
			/* We got some data, pass it up to our client. */
			var sequenceNumber = UInt16(0)
			var packet = Data(bytes: buffer, count: bytesRead)
			
			if validatePingResponsePacket(&packet, sequenceNumber: &sequenceNumber) {
				delegate?.simplePing(self, didReceivePingResponsePacket: packet, sequenceNumber: sequenceNumber)
			} else {
				delegate?.simplePing(self, didReceiveUnexpectedPacket: packet)
			}
		} else {
			/* Error reading from the socket. We shut everything down. */
			didFail(error: NSError(domain: NSPOSIXErrorDomain, code: Int(err != 0 ? err : EPIPE), userInfo: nil))
		}
		
		/* Note that we don't loop back trying to read more data. Rather, we just
		 * let CFSocket call us again. */
	}
	
	/** Starts the send and receive infrastructure.
	
	This is called once we've successfully resolved `hostName` in to
	`hostAddress`. It is responsible for setting up the socket for sending and
	receiving pings. */
	private func startWithHostAddress() {
		/* *** Open the socket. *** */
		
		let fd: Int32
		let err: Int32
		switch hostAddressFamily {
		case sa_family_t(AF_INET):
			fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
			if fd < 0 {err = errno}
			else      {err = 0}
			
		case sa_family_t(AF_INET6):
			fd = socket(AF_INET6, SOCK_DGRAM, IPPROTO_ICMPV6)
			if fd < 0 {err = errno}
			else      {err = 0}

		default:
			fd = -1
			err = EPROTONOSUPPORT
		}
		
		guard err == 0 else {
			didFail(error: NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil))
			return
		}
		
		/* *** Wrap it in a CFSocket and schedule it on the runloop. *** */
		
		var context = CFSocketContext(version: 0, info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self), retain: nil, release: nil, copyDescription: nil)
		sock = CFSocketCreateWithNative(nil, fd, CFSocketCallBackType.readCallBack.rawValue, socketReadCallback, &context)
		assert(sock != nil)
		
		/* *** The socket will now take care of cleaning up our file descriptor. *** */
		
		assert(CFSocketGetSocketFlags(sock) & kCFSocketCloseOnInvalidate != 0)
		let rls = CFSocketCreateRunLoopSource(nil, sock, 0)
		assert(rls != nil)
		
		CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, CFRunLoopMode.defaultMode)
		delegate?.simplePing(self, didStart: hostAddress!)
	}
	
	/** Processes the results of our name-to-address resolution.
	
	Called by our CFHost resolution callback (HostResolveCallback) when host
	resolution is complete. We just latch the first appropriate address and kick
	off the send and receive infrastructure. */
	fileprivate func hostResolutionDone() {
		/* *** Find the first appropriate address. *** */
		
		var resolved = DarwinBoolean(false)
		let addresses = CFHostGetAddressing(host!, &resolved)?.retain().autorelease()
		if resolved.boolValue, let addresses = addresses?.takeUnretainedValue() as? [Data] {
			resolved = false
			for address in addresses {
				assert(hostAddress == nil)
				guard address.count >= MemoryLayout<sockaddr>.size else {continue}				
                address.withUnsafeBytes { (addrPtr: UnsafeRawBufferPointer) in
                    guard let pointer = addrPtr.baseAddress?.assumingMemoryBound(to: sockaddr.self) else {
                        return
                    }
                    
                    switch (pointer.pointee.sa_family, addressStyle) {
                    case (sa_family_t(AF_INET),  .any), (sa_family_t(AF_INET),  .icmpV4):
                        hostAddress = address
                        resolved = true
                    case (sa_family_t(AF_INET6), .any), (sa_family_t(AF_INET6), .icmpV6):
                        hostAddress = address
                        resolved = true
                    default:
                        // Do nothing
                        break
                    }
                }
				if resolved.boolValue {break}
			}
		}
		
		/* *** We’re done resolving, so shut that down. *** */
		
		stopHostResolution()
		
		/* *** If all is OK, start the send and receive infrastructure, otherwise stop. *** */
		
		if resolved.boolValue {
			assert(hostAddress != nil)
			startWithHostAddress()
		} else {
			didFail(error: NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue), userInfo: nil))
		}
	}
	
	/** Stops the name-to-address resolution infrastructure. */
	private func stopHostResolution() {
		/* Shut down the CFHost. */
		guard let h = host else {return}
		
		host = nil
		CFHostSetClient(h, nil, nil)
		CFHostUnscheduleFromRunLoop(h, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
	}
	
	/** Stops the send and receive infrastructure. */
	private func stopSocket() {
		guard let s = sock else {return}
		
		sock = nil
		CFSocketInvalidate(s)
	}
	
}

/** The callback for our CFSocket object.

This simply routes the call to our `-readData` method.

- parameter s: See the documentation for CFSocketCallBack.
- parameter type: See the documentation for CFSocketCallBack.
- parameter address: See the documentation for CFSocketCallBack.
- parameter data: See the documentation for CFSocketCallBack.
- parameter info: See the documentation for CFSocketCallBack; this is actually a
pointer to the 'owning' object. */
private func socketReadCallback(s: CFSocket?, type: CFSocketCallBackType, address: CFData?, data: UnsafeRawPointer?, info: UnsafeMutableRawPointer?) -> Void {
	/* This C routine is called by CFSocket when there's data waiting on our ICMP
	 * socket. It just redirects the call to Swift code. */
	let obj = unsafeBitCast(info, to: SimplePing.self)
	assert(obj.sock === s)
	
	assert(type == CFSocketCallBackType.readCallBack)
	assert(address == nil)
	assert(data == nil)
	
	obj.readData()
}

/** The callback for our CFHost object.

This simply routes the call to our `-hostResolutionDone` or
`-didFailWithHostStreamError:` methods.

- parameter theHost: See the documentation for CFHostClientCallBack.
- parameter typeInfo: See the documentation for CFHostClientCallBack.
- parameter error: See the documentation for CFHostClientCallBack.
- parameter info: See the documentation for CFHostClientCallBack; this is
actually a pointer to the 'owning' object. */
private func hostResolveCallback(theHost: CFHost, typeInfo: CFHostInfoType, error: UnsafePointer<CFStreamError>?, info: UnsafeMutableRawPointer?) -> Void {
	/* This C routine is called by CFHost when the host resolution is complete.
	 * It just redirects the call to the appropriate Swift method. */
	let obj = unsafeBitCast(info, to: SimplePing.self)
	assert(obj.host === theHost)
	
	assert(typeInfo == CFHostInfoType.addresses)
	
	if let error = error, error.pointee.domain != 0 {obj.didFail(hostStreamError: error.pointee)}
	else                                            {obj.hostResolutionDone()}
}
