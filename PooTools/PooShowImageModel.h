//
//  PooShowImageModel.h
//  CloudGateCustom
//
//  Created by 邓杰豪 on 14/5/18.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PooShowImageModelType) {
    PooShowImageModelTypeNormal = 0,
    PooShowImageModelTypeGIF = 1,
    PooShowImageModelTypeVideo = 2,
    PooShowImageModelTypeFullView = 3
};

@interface PooShowImageModel : NSObject
@property (nonatomic, strong)NSString *imageTitle;
@property (nonatomic, strong)NSString *imageInfo;
@property (nonatomic, assign)PooShowImageModelType imageShowType;
@property (nonatomic, strong)NSString *imageUrl;
@end


