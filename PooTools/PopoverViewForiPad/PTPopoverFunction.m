//
//  PTPopoverFunction.m
//  PooTools_Example
//
//  Created by liu on 2020/1/8.
//  Copyright © 2020 crazypoo. All rights reserved.
//

#import "PTPopoverFunction.h"

#import "Utils.h"
#import <Masonry/Masonry.h>
#import "PMacros.h"

@implementation PTPopoverFunction
+(void)initWithContentViewSize:(CGSize)cSize withContentView:(UIView *)cView withSender:(UIView *)sender withSenderFrame:(CGRect)senderFrame withArrowDirections:(UIPopoverArrowDirection)arrowDirections withPopover:(ReturnView)block
{
    if (IS_IPAD)
    {
        //新建一个内容控制器
        UIViewController *infoViewController = [[UIViewController alloc] init];            //用于任何容器布局子控制器，弹出窗口的原始大小来自视图控制器的此属性，如果设置了此属性那么UIPopoverController的popoverContentSize属性会失效。
        infoViewController.preferredContentSize = cSize;
        //设置模态视图弹出的样式
        [infoViewController setModalPresentationStyle:UIModalPresentationPopover];
        
        [infoViewController.view addSubview:cView];
        [cView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(infoViewController.view);
        }];

        //UIPopoverPresentationController是UIViewController实例的属性，不需要创建，获取就可以啦
        UIPopoverPresentationController *presentationCtr = infoViewController.popoverPresentationController;
        //设置弹出窗口所依附的控件
        presentationCtr.sourceView = sender;
        //设置弹出窗口对所依附的控件的参考位置
        presentationCtr.sourceRect = senderFrame;//CGRectMake(self.view.frame.size.width/2, [CGBuildingInfoCollectionViewCell cellSize].height-TextAndTextSpace*2, 1, 1);
        //设置箭头方向
        presentationCtr.permittedArrowDirections = arrowDirections;
        block(infoViewController);
        //设置代理
        //弹出模态视图
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[Utils getCurrentVC] presentViewController:infoViewController animated:NO completion:nil];
        }];
    }
    else
    {
        PNSLog(@"暂不支持iPhone");
//        CGFloat dilH = [YXCustomAlertView titleAndBottomViewNormalHeighEXAlertW:cSize.width withTitle:@"" withTitleFont:kDEFAULT_FONT(kDevLikeFont, 16) withButtonArr:@[]] + cSize.height;
//
//
//        AlertAnimationType alertAnimationType;
//        switch (arrowDirections) {
//            case UIPopoverArrowDirectionUp:
//            {
//                alertAnimationType = AlertAnimationTypeTop;
//            }
//                break;
//            case UIPopoverArrowDirectionLeft:
//            {
//               alertAnimationType = AlertAnimationTypeLeft;
//            }
//                break;
//            case UIPopoverArrowDirectionRight:
//            {
//               alertAnimationType = AlertAnimationTypeRight;
//            }
//                break;
//            case UIPopoverArrowDirectionDown:
//            {
//                alertAnimationType = AlertAnimationTypeBottom;
//            }
//                break;
//            default:
//            {
//                if (senderFrame.origin.x<cSize.width && senderFrame.origin.y<cSize.height && (senderFrame.origin.y+cSize.height)<kSCREEN_HEIGHT) {
//                    arrowDirections = UIPopoverArrowDirectionUp;
//                    alertAnimationType = AlertAnimationTypeTop;
//                }
//                else if((kSCREEN_WIDTH-(senderFrame.origin.x+senderFrame.size.width+10))>cSize.width && (senderFrame.origin.x+senderFrame.size.height/2)>(HEIGHT_STATUS+cSize.height))
//                {
//                    arrowDirections = UIPopoverArrowDirectionLeft;
//                    alertAnimationType = AlertAnimationTypeLeft;
//                }
//                else if((kSCREEN_WIDTH-(senderFrame.origin.x-10))>cSize.width && (senderFrame.origin.x+senderFrame.size.height/2)>(HEIGHT_STATUS+cSize.height))
//                {
//                    arrowDirections = UIPopoverArrowDirectionRight;
//                    alertAnimationType = AlertAnimationTypeRight;
//                }
//                else
//                {
//                    arrowDirections = UIPopoverArrowDirectionDown;
//                    alertAnimationType = AlertAnimationTypeBottom;
//                }
//            }
//                break;
//        }
//
//        YXCustomAlertView *alertView = [[YXCustomAlertView alloc] initAlertViewWithSuperView:kAppDelegateWindow alertTitle:nil withButtonAndTitleFont:nil titleColor:nil bottomButtonTitleColor:nil verLineColor:nil alertViewBackgroundColor:nil heightlightedColor:nil moreButtonTitleArray:@[] viewTag:0 viewAnimation:alertAnimationType touchBackGround:YES setCustomView:^(YXCustomAlertView * _Nonnull alertView) {
//            block(alertView);
//            [alertView.customView addSubview:cView];
//            [cView mas_makeConstraints:^(MASConstraintMaker *make) {
//                switch (arrowDirections) {
//                    case UIPopoverArrowDirectionUp:
//                    {
//                        make.top.equalTo(alertView.customView).offset(10);
//                        make.left.right.bottom.equalTo(alertView.customView);
//                    }
//                        break;
//                    case UIPopoverArrowDirectionLeft:
//                    {
//                        make.right.top.bottom.equalTo(alertView.customView);
//                        make.left.equalTo(alertView.customView).offset(10);
//                    }
//                        break;
//                    case UIPopoverArrowDirectionRight:
//                    {
//                        make.left.right.top.bottom.equalTo(alertView.customView);
//                        make.right.equalTo(alertView.customView).offset(-10);
//                    }
//                        break;
//                    case UIPopoverArrowDirectionDown:
//                    {
//                        make.left.right.top.equalTo(alertView.customView);
//                        make.bottom.equalTo(alertView.customView).offset(-10);
//                    }
//                        break;
//                    default:
//                    {
//                        make.left.right.top.bottom.equalTo(alertView.customView);
//                    }
//                        break;
//                }
//            }];
//        } clickAction:^(YXCustomAlertView * _Nonnull alertView, NSInteger buttonIndex) {
//
//        } didDismissBlock:^(YXCustomAlertView * _Nonnull alertView) {
//
//        }];
//        [alertView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.width.offset(cSize.width);
//            make.height.offset(dilH);
//            switch (arrowDirections) {
//                case UIPopoverArrowDirectionUp:
//                {
//                    make.top.equalTo(sender.mas_bottom);
//
//                    if ((senderFrame.origin.x+cSize.width)>kSCREEN_WIDTH)
//                    {
//                        make.right.equalTo(kAppDelegateWindow).offset(-10);
//                    }
//                    else if (senderFrame.origin.x<cSize.width)
//                    {
//                        make.left.equalTo(kAppDelegateWindow).offset(senderFrame.origin.x);
//                    }
//                    else
//                    {
//                        make.centerX.equalTo(sender);
//                    }
//                }
//                    break;
//                case UIPopoverArrowDirectionLeft:
//                {
//                    if (senderFrame.origin.y>HEIGHT_STATUS && senderFrame.origin.y<(HEIGHT_STATUS+cSize.height))
//                    {
//                        make.top.equalTo(kAppDelegateWindow).offset(HEIGHT_STATUS);
//                    }
//                    else
//                    {
//                        make.centerY.equalTo(sender);
//                    }
//                    make.left.equalTo(sender.mas_right);
//                }
//                    break;
//                case UIPopoverArrowDirectionRight:
//                {
//                    if (senderFrame.origin.y>HEIGHT_STATUS && senderFrame.origin.y<(HEIGHT_STATUS+cSize.height))
//                    {
//                        make.top.equalTo(kAppDelegateWindow).offset(HEIGHT_STATUS);
//                    }
//                    else
//                    {
//                        make.centerY.equalTo(sender);
//                    }
//                    make.right.equalTo(sender.mas_left);
//                }
//                    break;
//                case UIPopoverArrowDirectionDown:
//                {
//                    make.bottom.equalTo(sender.mas_top);
//                    if (senderFrame.origin.x<cSize.width)
//                    {
//                        make.left.equalTo(kAppDelegateWindow).offset(10);
//                    }
//                    else if ((senderFrame.origin.x+cSize.width)>kSCREEN_WIDTH)
//                    {
//                        make.right.equalTo(kAppDelegateWindow).offset(-10);
//                    }
//                    else
//                    {
//                        make.centerX.equalTo(sender);
//                    }
//                }
//                    break;
//                default:
//                    break;
//            }
//        }];
//
    }
}

@end
