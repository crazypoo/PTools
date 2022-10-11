//
//  AMKLaunchTimeProfilerLogModel.m
//  AMKLaunchTimeProfiler
//
//  Created by mengxinxin on 2022/5/9.
//

#import "AMKLaunchTimeProfilerLogModel.h"
#import <YYModel/YYModel.h>

@implementation AMKLaunchTimeProfilerLogModel

#pragma mark - Init Methods

- (void)dealloc {
    
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - Getters & Setters

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"⏱ +%.3f s ~Δ %4.0f ms >>", self.timeInterval, self.timeDelta*1000];
    if (self.function) [description appendFormat:@" %@", self.function];
    if (self.line) [description appendFormat:@" Line %ld", (long)self.line];
    if (self.function || self.line) [description appendFormat:@":"];
    [description appendFormat:@" %@", self.string?:@""];
    return description;
}

#pragma mark - Data & Networking

#pragma mark - Public Methods

#pragma mark - Private Methods

#pragma mark - Notifications

#pragma mark - KVO

#pragma mark - Protocol

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self yy_modelEncodeWithCoder:aCoder];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init]; return [self yy_modelInitWithCoder:aDecoder];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [self yy_modelCopy];
}

#pragma mark - Overrides

- (NSUInteger)hash {
    return [self yy_modelHash];
}

- (BOOL)isEqual:(id)object {
    return [self yy_modelIsEqual:object];
}

- (NSString *)debugDescription {
    return [self yy_modelDescription];
}

#pragma mark - Helper Methods

@end
