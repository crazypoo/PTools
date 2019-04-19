//
//  PooNumberKeyBoard.h
//  numKeyBoard
//
//  Created by crazypoo on 14-4-3.
//  Copyright (c) 2014年 crazypoo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PKeyboardType) {
    PKeyboardTypeNormal,
    PKeyboardTypeCall,
    PKeyboardTypePoint,
    PKeyboardTypeInputID
};


@class PooNumberKeyBoard;

typedef void (^PooNumberKeyBoardBackSpace)(PooNumberKeyBoard *keyboardView);
typedef void (^PooNumberKeyBoardReturnSTH)(PooNumberKeyBoard *keyboardView,NSString *returnSTH);

@protocol PooNumberKeyBoardDelegate <NSObject>
@optional
- (void)numberKeyboard:(PooNumberKeyBoard *)keyboard input:(NSString *)number;
- (void)numberKeyboardBackspace:(PooNumberKeyBoard *)keyboard;
@end

@interface PooNumberKeyBoard : UIView
//@property (nonatomic, assign)BOOL haveDog;
@property (nonatomic, assign)id<PooNumberKeyBoardDelegate> delegate;

/*! @brief 初始化(Delegate)
 */
+(instancetype)pooNumberKeyBoardWithType:(PKeyboardType)keyboardType;
/*! @brief 初始化(Block)
 */
+(instancetype)pooNumberKeyBoardWithType:(PKeyboardType)keyboardType
                              backSpace:(PooNumberKeyBoardBackSpace)backSpaceBlock
                              returnSTH:(PooNumberKeyBoardReturnSTH)returnSTHBlock;

@end
