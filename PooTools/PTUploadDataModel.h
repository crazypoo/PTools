//
//  PTUploadDataModel.h
//  PooTools_Example
//
//  Created by 邓杰豪 on 2018/12/22.
//  Copyright © 2018年 crazypoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CGUploadType) {
    CGUploadTypeGIF,
    CGUploadTypeJPG,
    CGUploadTypePNG,
    CGUploadTypeJPEG,
    CGUploadTypeMP4,
    CGUploadTypeAUDIO,
    CGUploadTypeFLV,
    CGUploadTypeMP3,
    CGUploadTypeFULLVIEW
};

NS_ASSUME_NONNULL_BEGIN

@interface PTUploadDataModel : NSObject
@property (nonatomic,strong) UIImage *uploadImage;
@property (nonatomic,assign) CGUploadType imageType;
@property (nonatomic,strong) NSString *imageName;
@property (nonatomic,strong) NSData *imageData;
@end

NS_ASSUME_NONNULL_END
