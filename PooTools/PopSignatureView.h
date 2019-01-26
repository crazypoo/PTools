//
//  PopSignatureView.h
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol  PopSignatureViewDelegate <NSObject>

- (void)onSubmitBtn:(UIImage*)signatureImg;
@optional
- (void)cancelSign;
@end

@interface PopSignatureView : UIView

@property (nonatomic, assign) id<PopSignatureViewDelegate> delegate;

-(instancetype)initWithNavColor:(UIColor *)navC maskString:(NSString *)mString withViewFontName:(NSString *)fName withNavFontName:(NSString *)nfName;

- (void)show;
- (void)showInView:(UIView *)view;
- (id)initWithMainView:(UIView*)mainView;
- (void)hide;

@end
