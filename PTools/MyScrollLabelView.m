//
//  MyScrollLabelView.m
//  WNMPro
//
//  Created by Zhu Shouyu on 5/30/13.
//  Copyright (c) 2013 朱守宇. All rights reserved.
//

#import "MyScrollLabelView.h"

@interface MyScrollLabelView ()
{
    int timeCount;
}
@property (nonatomic, retain) UILabel *textLabel;


@end

@implementation MyScrollLabelView
@synthesize ZSYText = _ZSYText;
@synthesize ZSYTextColor = _ZSYTextColor;
@synthesize ZSYBackgroundColor = _ZSYBackgroundColor;
@synthesize ZSYFont = _ZSYFont;
@synthesize textLabel = _textLabel;
@synthesize textAlignment = _textAlignment;
@synthesize isScroll = _isScroll;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addObserver:self forKeyPath:@"ZSYText" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"ZSYTextColor" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"ZSYBackgroundColor" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"ZSYFont" options:NSKeyValueObservingOptionNew context:nil];
        _textLabel = [[UILabel alloc] initWithFrame:self.bounds];
        [_textLabel setBackgroundColor:[UIColor clearColor]];
        _textLabel.font = [UIFont systemFontOfSize:14.0f];
        _textLabel.textColor = [UIColor blackColor];
        [self addSubview:_textLabel];
        
        if (self.isScroll) {
            timeCount = 0;
            [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(scrollTimer) userInfo:nil repeats:YES];
        }
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"ZSYText"])
    {
        NSString *labelTitle = [[change objectForKey:@"new"] isEqual:[NSNull null]] ? @"" : [change objectForKey:@"new"];
        CGSize textLabelSize = CGSizeZero;
        if (labelTitle && [labelTitle length])
        {
            textLabelSize = [labelTitle sizeWithAttributes:@{NSFontAttributeName:self.textLabel.font}];
        }
        self.textLabel.text = labelTitle;
        CGRect frame = self.textLabel.frame;
        CGSize newSize = CGSizeMake(textLabelSize.width, frame.size.height);
        frame.size = newSize;
        self.textLabel.frame = frame;
        [self setContentSize:textLabelSize];
    }
    else if ([keyPath isEqualToString:@"ZSYTextColor"])
    {
        UIColor *color = [[change objectForKey:@"new"] isEqual:[NSNull null]] ? nil : [change objectForKey:@"new"];
        self.textLabel.textColor = color;
    }
    else if ([keyPath isEqualToString:@"ZSYBackgroundColor"])
    {
        UIColor *backgroundColor = [[change objectForKey:@"new"] isEqual:[NSNull null]] ? nil : [change objectForKey:@"new"];
        [self setBackgroundColor:backgroundColor];
    }
    else if ([keyPath isEqualToString:@"ZSYFont"])
    {
        UIFont *font = [[change objectForKey:@"new"] isEqual:[NSNull null]] ? nil : [change objectForKey:@"new"];
        self.textLabel.font = font;
    }
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    self.textLabel.textAlignment = textAlignment;
}

-(void)scrollTimer{
    timeCount ++;
    if (timeCount > self.textLabel.frame.size.width/self.frame.size.width) {
        timeCount = 0;
    }
    [self scrollRectToVisible:CGRectMake(timeCount *self.frame.size.width, self.frame.origin.y, self.frame.size.width, self.frame.size.height) animated:YES];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"ZSYText"];
    [self removeObserver:self forKeyPath:@"ZSYTextColor"];
    [self removeObserver:self forKeyPath:@"ZSYBackgroundColor"];
    [self removeObserver:self forKeyPath:@"ZSYFont"];
    
    self.textLabel = nil;
    self.ZSYText = nil;
    self.ZSYTextColor = nil;
    self.backgroundColor = nil;
    self.ZSYFont = nil;
}
@end
