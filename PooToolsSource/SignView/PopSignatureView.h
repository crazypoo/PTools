//
//  PopSignatureView.h
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PopSignatureView;

typedef void (^PooSignDoneBlock)(PopSignatureView *signView, UIImage *signImage);
typedef void (^PooSignCancelBlock)(PopSignatureView *signView);

@interface PopSignatureView : UIView

-(instancetype)initWithNavColor:(UIColor *)navC
                     maskString:(NSString *)mString
               withViewFontName:(NSString *)fName
                withNavFontName:(NSString *)nfName
              withLinePathWidth:(CGFloat)linePathWidth
              withBtnTitleColor:(UIColor *)btnColor
                     handleDone:(PooSignDoneBlock)doneBlock
                   handleCancle:(PooSignCancelBlock)cancelBlock;

- (void)show;
- (void)showInView:(UIView *)view;
- (id)initWithMainView:(UIView*)mainView;
- (void)hide;

@end
