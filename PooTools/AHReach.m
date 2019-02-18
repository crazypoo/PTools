//
//  AHReach.m
//
//  Copyright (c) 2012 Auerhaus Development, LLC
//  
//  Permission is hereby granted, free of charge, to any person obtaining a 
//  copy of this software and associated documentation files (the "Software"), 
//  to deal in the Software without restriction, including without limitation 
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, 
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included 
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
//  IN THE SOFTWARE.
//  

#import "AHReach.h"
#import <SystemConfiguration/SystemConfiguration.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <netdb.h>

enum {
	AHReachRouteNone = 0,
	AHReachRouteWiFi = 1,
	AHReachRouteWWAN = 2,
};

typedef NSInteger AHReachRoutes;

@interface AHReach ()
@property(nonatomic) SCNetworkReachabilityRef reachability;
@property(nonatomic, copy) AHReachChangedBlock changedBlock;
@end

void AHReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

@implementation AHReach

@synthesize reachability, changedBlock;

#pragma mark - Factory methods

+ (AHReach *)reachForHost:(NSString *)host {
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
	return [[AHReach alloc] initWithReachability:reachabilityRef];
}

+ (AHReach *)reachForAddress:(const struct sockaddr_in *)addr {
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr *)addr);
	return [[AHReach alloc] initWithReachability:reachabilityRef];
}

+ (AHReach *)reachForDefaultHost {
	return [self reachForHost:@kAHReachDefaultHost];
}

#pragma mark - Object lifetime

- (id)initWithReachability:(SCNetworkReachabilityRef)reachabilityRef {
	if((self = [super init]) && reachabilityRef) {
		reachability = reachabilityRef;
		return self;
	}
	return nil;
}

- (void)dealloc {
    [self stopUpdating];
    if(reachability) {
        CFRelease(reachability);
        reachability = NULL;
    }
    [super dealloc];
}

#pragma mark - Reachability and notification methods

- (AHReachRoutes)availableRoutes {
	AHReachRoutes routes = AHReachRouteNone;
	SCNetworkReachabilityFlags flags = 0;
	SCNetworkReachabilityGetFlags(self.reachability, &flags);
	
	if(flags & kSCNetworkReachabilityFlagsReachable)
	{
		// Since WWAN is likely to require a connection, we initially assume a route with no connection required is WiFi
		if(!(flags & kSCNetworkReachabilityFlagsConnectionRequired)) {
			routes |= AHReachRouteWiFi;
		}
		
		BOOL automatic = (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) || 
		                 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic);
		
		// Alternatively, a connection that connects on-demand/-traffic without intervention required might be WiFi too
		if(automatic && !(flags & kSCNetworkReachabilityFlagsInterventionRequired)) {
			routes |= AHReachRouteWiFi;
		}
		
		// But if we're told explicitly that we're on WWAN, we throw away all earlier knowledge and just report WWAN
		if(flags & kSCNetworkReachabilityFlagsIsWWAN) {
			routes &= ~AHReachRouteWiFi;
			routes |= AHReachRouteWWAN;
		}
	}

	return routes;
}

- (BOOL)isReachable {
	return [self availableRoutes] != AHReachRouteNone;
}

- (BOOL)isReachableViaWWAN {
	return [self availableRoutes] & AHReachRouteWWAN;
}

- (BOOL)isReachableViaWiFi {
	return [self availableRoutes] & AHReachRouteWiFi;
}

- (void)startUpdatingWithBlock:(AHReachChangedBlock)block {
	if(block && self.reachability) {
		self.changedBlock = block;
		SCNetworkReachabilityContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };
		SCNetworkReachabilitySetCallback(self.reachability, AHReachabilityCallback, &context);
		SCNetworkReachabilityScheduleWithRunLoop(self.reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	} else {
		[self stopUpdating];
	}
}

- (void)reachabilityDidChange {
	if(self.changedBlock)
		self.changedBlock(self);
}

- (void)stopUpdating {
	self.changedBlock = nil;
	
	if(self.reachability) {
		SCNetworkReachabilityUnscheduleFromRunLoop(self.reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		SCNetworkReachabilitySetCallback(self.reachability, NULL, NULL);
	}
}

@end

#pragma mark - Reachability callback function

void AHReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
	AHReach *reach = (__bridge AHReach *)info;
	[reach reachabilityDidChange];
}
