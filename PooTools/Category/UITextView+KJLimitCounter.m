//
//  UITextView+KJLimitCounter.m
//  CategoryDemo
//
//  Created by 杨科军 on 2018/7/12.
//  Copyright © 2018年 杨科军. All rights reserved.
//

#import "UITextView+KJLimitCounter.h"
#import <objc/runtime.h>

@implementation UITextView (KJLimitCounter)
@dynamic kj_LabFont;
+ (void)load {
    [super load];
    method_exchangeImplementations(class_getInstanceMethod(self.class, NSSelectorFromString(@"layoutSubviews")),
                                   class_getInstanceMethod(self.class, @selector(kj_limitCounter_swizzling_layoutSubviews)));
    method_exchangeImplementations(class_getInstanceMethod(self.class, NSSelectorFromString(@"dealloc")),
                                   class_getInstanceMethod(self.class, @selector(kj_limitCounter_swizzled_dealloc)));
}
#pragma mark - swizzled
- (void)kj_limitCounter_swizzled_dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try {
        [self removeObserver:self forKeyPath:@"layer.borderWidth"];
        [self removeObserver:self forKeyPath:@"text"];
    } @catch (NSException *exception){
    } @finally {
    }
    [self kj_limitCounter_swizzled_dealloc];
}
- (void)kj_limitCounter_swizzling_layoutSubviews {
    [self kj_limitCounter_swizzling_layoutSubviews];
    if (self.kj_LimitCount){
        UIEdgeInsets textContainerInset = self.textContainerInset;
        textContainerInset.bottom = self.kj_LabHeight;
        self.contentInset = textContainerInset;
        CGFloat x = CGRectGetMinX(self.frame)+self.layer.borderWidth;
        CGFloat y = CGRectGetMaxY(self.frame)-self.contentInset.bottom-self.layer.borderWidth;
        CGFloat width = CGRectGetWidth(self.bounds)-self.layer.borderWidth*2;
        CGFloat height = self.kj_LabHeight;
        self.kj_InputLimitLabel.frame = CGRectMake(x, y, width, height);
        if ([self.superview.subviews containsObject:self.kj_InputLimitLabel]){
            return;
        }
        [self.superview insertSubview:self.kj_InputLimitLabel aboveSubview:self];
    }
}
#pragma mark - associated
-(NSInteger)kj_LimitCount{
    return [objc_getAssociatedObject(self, @selector(kj_LimitCount)) integerValue];
}
- (void)setKj_LimitCount:(NSInteger)kj_limitCount{
    objc_setAssociatedObject(self, @selector(kj_LimitCount), @(kj_limitCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updateLimitCount];
}
-(CGFloat)kj_LabMargin{
    return [objc_getAssociatedObject(self, @selector(kj_LabMargin))floatValue];
}
-(void)setKj_LabMargin:(CGFloat)kj_labMargin{
    objc_setAssociatedObject(self, @selector(kj_LabMargin), @(kj_labMargin), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updateLimitCount];
}
-(CGFloat)kj_LabHeight{
    return [objc_getAssociatedObject(self, @selector(kj_LabHeight)) floatValue];
}
-(void)setKj_LabHeight:(CGFloat)kj_labHeight{
    objc_setAssociatedObject(self, @selector(kj_LabHeight), @(kj_labHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updateLimitCount];
}
- (void)setKj_LabFont:(UIFont *)kj_labFont{
    self.kj_InputLimitLabel.font = kj_labFont;
}
#pragma mark - config
- (void)_configTextView{
    /// 设置默认值
    self.kj_LabHeight = 20;
    self.kj_LabMargin = 10;
    self.kj_LabFont = [UIFont systemFontOfSize:12];
}
#pragma mark - update
- (void)updateLimitCount{
    if (self.text.length > self.kj_LimitCount){
        UITextRange *markedRange = [self markedTextRange];
        if (markedRange){
            return;
        }
        NSRange range = [self.text rangeOfComposedCharacterSequenceAtIndex:self.kj_LimitCount];
        self.text = [self.text substringToIndex:range.location];
    }
    NSString *showText = [NSString stringWithFormat:@"%lu/%ld",(unsigned long)self.text.length,(long)self.kj_LimitCount];
    self.kj_InputLimitLabel.text = showText;
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:showText];
    NSUInteger length = [showText length];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.tailIndent = -self.kj_LabMargin; //设置与尾部的距离
    style.alignment = NSTextAlignmentRight;//靠右显示
    [attrString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, length)];
    self.kj_InputLimitLabel.attributedText = attrString;
}
#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"layer.borderWidth"] ||
        [keyPath isEqualToString:@"text"]){
        [self updateLimitCount];
    }
}
#pragma mark - lazzing
- (UILabel *)kj_InputLimitLabel{
    UILabel *label = objc_getAssociatedObject(self, @selector(kj_InputLimitLabel));
    if (!label){
        label = [[UILabel alloc] init];
        label.backgroundColor = self.backgroundColor;
        label.textColor = [UIColor lightGrayColor];
        label.textAlignment = NSTextAlignmentRight;
        objc_setAssociatedObject(self, @selector(kj_InputLimitLabel), label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLimitCount) name:UITextViewTextDidChangeNotification object:self];
        [self addObserver:self forKeyPath:@"layer.borderWidth" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
        [self _configTextView];
    }
    return label;
}
@end
