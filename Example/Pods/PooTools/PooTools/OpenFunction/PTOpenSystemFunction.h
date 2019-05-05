//
//  PTOpenSystemFunction.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2019/3/23.
//  Copyright © 2019年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,SystemFunctionType){
    SystemFunctionTypeCall = 0,
    SystemFunctionTypeSMS,
    SystemFunctionTypeMail,
    SystemFunctionTypeAppStore,
    SystemFunctionTypeSafari,
    SystemFunctionTypeiBook,
    SystemFunctionTypeFaceTime,
    SystemFunctionTypeMap,
    SystemFunctionTypeMusic,
    SystemFunctionTypeBattery,
    SystemFunctionTypeLocation,
    SystemFunctionTypePrivace,
    SystemFunctionTypeSiri,
    SystemFunctionTypeSounds,
    SystemFunctionTypeWallpaper,
    SystemFunctionTypeDisplay,
    SystemFunctionTypeKeyboard,
    SystemFunctionTypeDateAndTime,
    SystemFunctionTypeAccessibilly,
    SystemFunctionTypeAbout,
    SystemFunctionTypeGeneral,
    SystemFunctionTypeNotification,
    SystemFunctionTypeMobileData,
    SystemFunctionTypeBluetooth,
    SystemFunctionTypeWIFI,
    SystemFunctionTypeCastle,
    SystemFunctionTypeSetting
    
};

@interface PTOpenSystemFunction : NSObject
+(void)openSystemFunction:(SystemFunctionType)type functionEx:(NSString *)ex withScheme:(NSString *)scheme;
@end
