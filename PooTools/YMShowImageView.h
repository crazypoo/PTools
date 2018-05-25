//
//  YMShowImageView.h
//  WFCoretext
//
//  Created by 阿虎 on 14/11/3.
//  Copyright (c) 2014年 tigerwf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PooShowImageModel.h"

@class YMShowImageView;

#define YMShowImageViewClickTagAppend 9999

typedef void(^didRemoveImage)(void);
typedef void(^YMShowImageViewDidDeleted) (YMShowImageView *siv,NSInteger index);

@interface YMShowImageView : UIView<UIScrollViewDelegate>{
    UIImageView *showImage;
    
    UIColor *titleColor;
    NSString *fontName;
    UIColor *currentPageIndicatorTintColor;
    UIColor *pageIndicatorTintColor;
    NSString *deleteImageName;
    UIColor *showImageBackgroundColor;
    UIWindow *window;
}

@property (nonatomic,copy) didRemoveImage removeImg;
@property (nonatomic,copy) YMShowImageViewDidDeleted didDeleted;
@property (nonatomic,strong) NSMutableArray *saveImageArr;
@property (nonatomic, copy) void(^saveImageStatus)(BOOL saveStatus);


- (void)showWithFinish:(didRemoveImage)tempBlock;

- (void)show:(UIView *)bgView didFinish:(didRemoveImage)tempBlock;

- (id)initWithFrame:(CGRect)frame byClick:(NSInteger)clickTag appendArray:(NSArray <PooShowImageModel*>*)appendArray titleColor:(UIColor *)tC fontName:(NSString *)fName currentPageIndicatorTintColor:(UIColor *)cpic pageIndicatorTintColor:(UIColor *)pic deleteImageName:(NSString *)di showImageBackgroundColor:(UIColor *)sibc showWindow:(UIWindow *)w loadingImageName:(NSString *)li deleteAble:(BOOL)canDelete saveAble:(BOOL)canSave saveImageImage:(NSString *)sii;
@end
