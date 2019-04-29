//
//  IGBannerItem.m
//  Demo
//
//  Created by 何桂强 on 14/10/30.
//  Copyright (c) 2014年 touchmob.com. All rights reserved.
//

#import "IGBannerItem.h"

@implementation IGBannerItem
@synthesize title,image,imageUrl,style,obj,tag;
- (id)initWithTitle:(NSString *)atitle image:(UIImage *)aimage tag:(int)atag{
    self = [super init];
    if (self) {
        self.title = atitle;
        self.image = aimage;
        self.style = IGBannerItemWithImage;
        self.tag = atag;
    }
    return self;
}

- (id)initWithTitle:(NSString *)atitle imageUrl:(NSString *)aimageUrl tag:(int)atag{
    self = [super init];
    if (self) {
        self.title = atitle;
        self.imageUrl = aimageUrl;
        self.style = IGBannerItemWithImageURL;
        self.tag = atag;
    }
    return self;
}

+ (id)itemWithTitle:(NSString *)atitle image:(UIImage *)aimage tag:(int)atag{
    return [[IGBannerItem alloc] initWithTitle:atitle image:aimage tag:atag];
}
+ (id)itemWithTitle:(NSString *)atitle imageUrl:(NSString *)aimageUrl tag:(int)atag{
    return [[IGBannerItem alloc] initWithTitle:atitle imageUrl:aimageUrl tag:atag];
}
@end
