//
//  NSString+PassStrength.h
//  PooTools_Example
//
//  Created by crazypoo on 2019/6/8.
//  Copyright © 2019 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PTStrengthLevel) {
    PTStrengthLevelEASY = 0,
    PTStrengthLevelMIDIUM,
    PTStrengthLevelSTRONG,
    PTStrengthLevelVERY_STRONG,
    PTStrengthLevelEXTREMELY_STRONG
};

@interface NSString (PassStrength)
/**
 获取密码强度等级，包括easy, midium, strong, very strong, extremely strong
 @return 密码强度
 */
- (PTStrengthLevel)passwordLevel;
@end
