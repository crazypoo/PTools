//
//  YNPayPasswordView.m
//  O2O
//
//  Created by Abel on 16/11/9.
//  Copyright © 2016年 yunshanghui. All rights reserved.
//

#import "YNPayPasswordView.h"
#import <Masonry/Masonry.h>
#import "PMacros.h"

#define boxWidth  40//密码框的宽度
#define HLDefaultBGColor [UIColor colorWithRed:248.0f/255.0f green:248.0f/255.0f blue:248.0f/255.0f alpha:1.0f]
#define HLLineColor [UIColor lightGrayColor]
#define HLTextRedColor [UIColor redColor]

@interface YNPayPasswordView ()
@property (strong,nonatomic) NSString *viewTitleString;
@property (strong,nonatomic) NSString *subTitleString;

@property (strong,nonatomic) NSArray *buttonArray;

@property (nonatomic,strong) UITextField *inputTextField;

//@property (nonatomic,copy) InputViewBtnBlock block;
//@property (nonatomic,copy) InputViewDismissBlock dismissBlock;
@property (nonatomic) void (^ _Nonnull InputViewBtnBlock)(YNPayPasswordView * _Nonnull inputView, NSInteger buttonIndex, NSString * _Nonnull inputText);
@property (nonatomic) void (^ _Nonnull InputViewDismissBlock)(void);

@property (nonatomic,strong) UIFont *viewFont;

@end

@implementation YNPayPasswordView

-(instancetype _Nonnull)initWithTitle:(NSString * _Nonnull)title
                         WithSubTitle:(NSString * _Nonnull)subTitle
                           WithButton:(NSArray * _Nonnull )bttonArray
                        withTitleFont:(UIFont * _Nullable)font
                               handle:(void (^_Nonnull)(YNPayPasswordView * _Nonnull inputView, NSInteger buttonIndex, NSString * _Nonnull inputText))block
                              dismiss:(void (^_Nonnull)(void))dismissBlock
{
    self = [super init];
    if (self)
    {
        self.InputViewBtnBlock = block;
        self.viewTitleString = title;
        self.subTitleString = subTitle;
        self.buttonArray = bttonArray;
//        self.block = block;
        self.viewFont = font ? font : kDEFAULT_FONT(kDevLikeFont, 16);
//        self.dismissBlock = dismissBlock;
        self.InputViewDismissBlock = dismissBlock;
    }
    return self;
}

- (void)loadView
{
    UIFont *titleFont = self.viewFont ? self.viewFont : kDEFAULT_FONT(kDevLikeFont, 15);
    UIFont *subTitleFont = self.viewFont ? kDEFAULT_FONT(self.viewFont.familyName, self.viewFont.pointSize+5) : kDEFAULT_FONT(kDevLikeFont, 20);

    UIView *viewBG = [UIView new];
    viewBG.backgroundColor = kDevMaskBackgroundColor;
    [self addSubview:viewBG];
    [viewBG mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    
    UIView *view = [UIView new];
    [view.layer setCornerRadius:3];
    [view.layer setMasksToBounds:YES];
    view.backgroundColor = [UIColor whiteColor];
    [viewBG addSubview:view];

    UILabel *lable_title = [UILabel new];
    lable_title.text = self.viewTitleString;
    lable_title.textAlignment = NSTextAlignmentCenter;
    lable_title.font = titleFont;
    lable_title.textColor = [UIColor lightGrayColor];
    [view addSubview:lable_title];
    [lable_title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view).offset(10);
        make.right.equalTo(view).offset(-10);
        make.top.equalTo(view).offset(20);
        make.height.offset(15);
    }];

    UILabel *lable_subTitle = [UILabel new];
    lable_subTitle.text = self.subTitleString ? self.subTitleString : @"";
    lable_subTitle.textAlignment = NSTextAlignmentCenter;
    lable_subTitle.numberOfLines = 0;
    lable_subTitle.lineBreakMode = NSLineBreakByCharWrapping;
    lable_subTitle.font = subTitleFont;
    lable_subTitle.textColor = [UIColor redColor];
    [view addSubview:lable_subTitle];
    if (kStringIsEmpty(self.subTitleString))
    {
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.offset(275);
            make.height.offset(158);
            make.centerX.equalTo(viewBG);
            make.top.offset(70);
        }];

        [lable_subTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(view).offset(10);
            make.right.equalTo(view).offset(-10);
            make.top.equalTo(lable_title.mas_bottom).offset(20);
            make.height.offset(0);
        }];
    }
    else
    {
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.offset(275);
            make.height.offset(198);
            make.centerX.equalTo(viewBG);
            make.top.offset(70);
        }];

        [lable_subTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(view).offset(10);
            make.right.equalTo(view).offset(-10);
            make.top.equalTo(lable_title.mas_bottom).offset(20);
            make.height.offset(20);
        }];
    }

    self.inputTextField = [UITextField new];
    self.inputTextField.frame = CGRectMake(0, 0, 0, 0);
    self.inputTextField.delegate = self;
    self.inputTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.inputTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [view addSubview:self.inputTextField];
    if (![self.inputTextField becomeFirstResponder]){
        [self.inputTextField becomeFirstResponder];
    }
    
    for (int i = 0; i < 6; i++)
    {
        UIView *view_box = [UIView new];
        [view_box.layer setBorderWidth:0.5];
        view_box.backgroundColor = HLDefaultBGColor;
        view_box.layer.borderColor = [HLLineColor CGColor];
        view_box.tag = i+1000;
        [view addSubview:view_box];
        [view_box mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(view).offset((275-boxWidth*6)/2+boxWidth*i);
            make.top.equalTo(lable_subTitle.mas_bottom).offset(20);
            make.width.height.offset(boxWidth);
        }];

        UILabel *lable_point = [UILabel new];
        [lable_point.layer setCornerRadius:5];
        [lable_point.layer setMasksToBounds:YES];
        lable_point.backgroundColor = [UIColor blackColor];
        lable_point.tag = i+2000;
        [view_box addSubview:lable_point];
        [lable_point mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.offset(10);
            make.centerX.centerY.equalTo(view_box);
        }];
        lable_point.hidden=YES;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inputTap:)];
        [view_box addGestureRecognizer:tap];

    }
    
    UIView *view_box = [self viewWithTag:1000];
    UIView *line = [UIView new];
    line.backgroundColor = HLLineColor;
    [view addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(view);
        make.top.equalTo(view_box.mas_bottom).offset(15);
        make.height.offset(0.5);
    }];
    
    for(int i=0;i < self.buttonArray.count;i++)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor darkGrayColor] forState:0];
        btn.backgroundColor = [UIColor clearColor];
        btn.titleLabel.font = self.viewFont;
        [btn setTitle:[self.buttonArray objectAtIndex:i] forState:0];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = i;
        [view addSubview:btn];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(view).offset((275/self.buttonArray.count)*i);
            make.width.offset(275/self.buttonArray.count);
            make.top.equalTo(line.mas_bottom);
            make.bottom.equalTo(view);
        }];
        if(i == self.buttonArray.count-1)
        {
            [btn setTitleColor:[UIColor redColor] forState:0];
        }
        else
        {
            UIView *line1 = [UIView new];
            line1.backgroundColor = HLLineColor;
            [view addSubview:line1];
            [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.equalTo(view);
                make.width.offset(0.5);
                make.top.equalTo(line.mas_bottom);
                make.bottom.equalTo(view);
            }];
        }
    }
}

-(void)show
{
    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews animations:^{
        
        [kAppDelegateWindow addSubview:self];
        [self mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(kAppDelegateWindow);
        }];

    } completion:NULL];
    
    [self loadView];
}

-(void)textFieldDidChange:(id) sender {
    
    UITextField *field = (UITextField *)sender;
    
    for (int i = 0; i < 6; i++) {
        UILabel *aaaaa = [self viewWithTag:2000+i];
        switch (field.text.length) {
            case 0:
                {
                    aaaaa.hidden = YES;
                }
                break;
            case 1:
            {
                if (i == 0) {
                    aaaaa.hidden = NO;
                }
                else
                {
                    aaaaa.hidden = YES;
                }
            }
                break;
            case 2:
            {
                if (i == 0 || i == 1) {
                    aaaaa.hidden = NO;
                }
                else
                {
                    aaaaa.hidden = YES;
                }
            }
                break;
            case 3:
            {
                if (i == 0 || i == 1 || i == 2) {
                    aaaaa.hidden = NO;
                }
                else
                {
                    aaaaa.hidden = YES;
                }
            }
                break;
            case 4:
            {
                if (i == 0 || i == 1 || i == 2 || i == 3) {
                    aaaaa.hidden = NO;
                }
                else
                {
                    aaaaa.hidden = YES;
                }
            }
                break;
            case 5:
            {
                if (i == 0 || i == 1 || i == 2 || i == 3 || i == 4) {
                    aaaaa.hidden = NO;
                }
                else
                {
                    aaaaa.hidden = YES;
                }
            }
                break;
            default:
            {
                aaaaa.hidden = NO;
            }
                break;
        }
    }
    
    if(field.text.length>6)
    {
        field.text = [field.text substringToIndex:6];
    }
}

- (void)btnClick:(UIButton *)btn
{
    self.InputViewBtnBlock(self, btn.tag , self.inputTextField.text);
}

- (void)hiddenAllPoint
{
    for (int i = 0; i < 6; i++) {
        UILabel *aaaaa = [self viewWithTag:2000+i];
        aaaaa.hidden = YES;
    }
}

- (void)removeFromView
{
    [self removeFromSuperview];
    self.InputViewDismissBlock();
}

-(void)inputTap:(UIGestureRecognizer *)gesture
{
    if (![self.inputTextField becomeFirstResponder]){
        [self.inputTextField becomeFirstResponder];
    }
}
@end
