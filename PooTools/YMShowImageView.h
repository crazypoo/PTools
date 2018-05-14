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
}

@property (nonatomic,copy) didRemoveImage removeImg;
@property (nonatomic,copy) YMShowImageViewDidDeleted didDeleted;
@property (nonatomic,strong)UIColor *titleColor;
@property (nonatomic,strong)NSString *fontName;
@property (nonatomic,strong)UIColor *currentPageIndicatorTintColor;
@property (nonatomic,strong)UIColor *pageIndicatorTintColor;
@property (nonatomic,strong)NSString *deleteImageName;
@property (nonatomic,strong)UIColor *showImageBackgroundColor;
@property (strong,nonatomic)UIWindow *window;

- (void)showWithFinish:(didRemoveImage)tempBlock;

- (void)show:(UIView *)bgView didFinish:(didRemoveImage)tempBlock;

- (id)initWithFrame:(CGRect)frame byClick:(NSInteger)clickTag appendArray:(NSArray <PooShowImageModel*>*)appendArray deleteAble:(BOOL)canDelete;
@end
