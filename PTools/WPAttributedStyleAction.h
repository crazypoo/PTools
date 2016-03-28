//
//  WPAttributedStyleAction.h
//  WPAttributedMarkupDemo
//
//  Created by Nigel Grange on 20/10/2014.
//  Copyright (c) 2014 Nigel Grange. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPAttributedStyleAction : NSObject

@property (readwrite, copy) void (^action) ();

- (instancetype)initWithAction:(void (^)())action;
+(NSArray*)styledActionWithAction:(void (^)())action;
-(NSArray*)styledAction;


@end

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com 
