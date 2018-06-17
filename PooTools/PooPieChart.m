//
//  PooPieChart.m
//  CloudGateCustom
//
//  Created by 邓杰豪 on 26/4/2018.
//  Copyright © 2018年 邓杰豪. All rights reserved.
//

#import "PooPieChart.h"

#define CHART_MARGIN 40

#define TO_RADIUS(value) ((value / M_PI) * 180)

@interface PooPieChart ()
{
    CGPoint centerPoint;
    UIFont *fontName;
    UIFont *centerFont;

}

@property (nonatomic, strong) NSMutableArray *modelArray;
@property (nonatomic, strong) NSMutableArray *colorArray;
@property (nonatomic, strong) NSMutableArray *totalArr;
@end


@implementation PooPieChart

- (instancetype)initWithFrame:(CGRect)frame lineFontName:(UIFont *)lName centerLabelFont:(UIFont *)cFont
{
    if (self = [super initWithFrame:frame])
    {
        fontName = lName;
        centerFont = cFont;
        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPieAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)draw
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
    CGFloat min = self.bounds.size.width > self.bounds.size.height ? self.bounds.size.height : self.bounds.size.width;
    
    centerPoint =  CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    CGFloat radius = min * 0.5 - CHART_MARGIN;
    CGFloat start = 0;
    CGFloat angle = 0;
    CGFloat end = start;
    
    if (self.dataArray.count == 0) {
        
        end = start + M_PI * 2;
        
        PooPieViewModel *model = self.dataArray[0];
        
        UIColor *color = model.color;
        
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:centerPoint radius:radius startAngle:start endAngle:end clockwise:true];
        
        [color set];
        
        //添加一根线到圆心
        [path addLineToPoint:centerPoint];
        [path fill];
        
    }
    else
    {        
        NSMutableArray *pointArray = [NSMutableArray array];
        NSMutableArray *centerArray = [NSMutableArray array];
        
        self.modelArray = [NSMutableArray array];
        self.colorArray = [NSMutableArray array];
        
        self.totalArr = [[NSMutableArray alloc] init];
        for (int j = 0; j < self.dataArray.count; j++)
        {
            PooPieViewModel *model = self.dataArray[j];
            [self.totalArr addObject:model.value];
        }
        
        for (int i = 0; i < self.dataArray.count; i++)
        {
            PooPieViewModel *model = self.dataArray[i];
            
            CGFloat percent = [model.value floatValue]/[[self.totalArr valueForKeyPath:@"@sum.floatValue"] floatValue];
            UIColor *color = model.color;
            
            start = end;
            
            angle = percent * M_PI * 2;
            
            end = start + angle;
            
            UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:centerPoint radius:radius startAngle:start endAngle:end clockwise:true];

            [color set];

            //添加一根线到圆心
            [path addLineToPoint:centerPoint];
            [path fill];
            
            // 获取弧度的中心角度
            CGFloat radianCenter = (start + end) * 0.5;
            
            
            // 获取指引线的起点
            CGFloat lineStartX = self.width * 0.5 + radius * cos(radianCenter);
            CGFloat lineStartY = self.height * 0.5 + radius * sin(radianCenter);
            
            
            CGPoint point = CGPointMake(lineStartX, lineStartY);
            
            if (i <= self.dataArray.count / 2 - 1) {
                [pointArray insertObject:[NSValue valueWithCGPoint:point] atIndex:0];
                [centerArray insertObject:[NSNumber numberWithFloat:radianCenter] atIndex:0];
                [self.modelArray insertObject:model atIndex:0];
                [self.colorArray insertObject:color atIndex:0];
            } else {
                [pointArray addObject:[NSValue valueWithCGPoint:point]];
                [centerArray addObject:[NSNumber numberWithFloat:radianCenter]];
                [self.modelArray addObject:model];
                [self.colorArray addObject:color];
            }
        }
        
        // 通过pointArray绘制指引线
        [self drawLineWithPointArray:pointArray centerArray:centerArray];
        
    }
    
    // 在中心添加label
    PooPieCenterView *centerView = [[PooPieCenterView alloc] initWithFrame:CGRectMake(0, 0, 80, 80) centerLabelFont:centerFont];
    CGRect frame = centerView.frame;
    frame.origin = CGPointMake(self.width * 0.5 - frame.size.width * 0.5, self.height * 0.5 - frame.size.width * 0.5);
    centerView.frame = frame;
    
    centerView.nameLabel.text = self.title;
    
    [self addSubview:centerView];
}

- (void)drawLineWithPointArray:(NSArray *)pointArray centerArray:(NSArray *)centerArray {
    
    // 记录每一个指引线包括数据所占用位置的和（总体位置）
    CGRect rect = CGRectZero;
    
    // 用于计算指引线长度
    CGFloat width = self.bounds.size.width * 0.5;
    
    for (int i = 0; i < pointArray.count; i++) {
        
        // 取出数据
        NSValue *value = pointArray[i];
        
        // 每个圆弧中心店的位置
        CGPoint point = value.CGPointValue;
        
        // 每个圆弧中心点的角度
        CGFloat radianCenter = [centerArray[i] floatValue];
        
        // 颜色（绘制数据时要用）
        UIColor *color = self.colorArray[i % 6];
        
        // 模型数据（绘制数据时要用）
        PooPieViewModel *model = self.modelArray[i];
        
        // 模型的数据
        CGFloat percent = [model.value floatValue]/[[self.totalArr valueForKeyPath:@"@sum.floatValue"] floatValue];

        NSString *name = model.name;
        NSString *number = [NSString stringWithFormat:@"%@元 占%.2f%%",model.value,percent*100];
        
        
        // 圆弧中心点的x值和y值
        CGFloat x = point.x;
        CGFloat y = point.y;
        
        // 指引线终点的位置（x, y）
        CGFloat startX = x + 10 * cos(radianCenter);
        CGFloat startY = y + 10 * sin(radianCenter);
        
        // 指引线转折点的位置(x, y)
        CGFloat breakPointX = x + 20 * cos(radianCenter);
        CGFloat breakPointY = y + 20 * sin(radianCenter);
        
        // 转折点到中心竖线的垂直长度（为什么+20, 在实际做出的效果中，有的转折线很丑，+20为了美化）
        CGFloat margin = fabs(width - breakPointX) + 20;
        
        // 指引线长度
        CGFloat lineWidth = width - margin;
        
        // 指引线起点（x, y）
        CGFloat endX;
        CGFloat endY;
        
        // 绘制文字和数字时，所占的size（width和height）
        // width使用lineWidth更好，我这么写固定值是为了达到产品要求
        CGFloat numberWidth = 150.f;
        CGFloat numberHeight = 25.f;
        
        CGFloat titleWidth = numberWidth;
        CGFloat titleHeight = numberHeight;
        
        // 绘制文字和数字时的起始位置（x, y）与上面的合并起来就是frame
        CGFloat numberX;// = breakPointX;
        CGFloat numberY = breakPointY - numberHeight;
        
        CGFloat titleX = breakPointX;
        CGFloat titleY = breakPointY + 2;
        
        
        // 文本段落属性(绘制文字和数字时需要)
        NSMutableParagraphStyle * paragraph = [[NSMutableParagraphStyle alloc]init];
        // 文字靠右
        paragraph.alignment = NSTextAlignmentRight;
        
        // 判断x位置，确定在指引线向左还是向右绘制
        // 根据需要变更指引线的起始位置
        // 变更文字和数字的位置
        if (x <= width) { // 在左边
            
            endX = 10;
            endY = breakPointY;
            
            // 文字靠左
            paragraph.alignment = NSTextAlignmentLeft;
            
            numberX = endX;
            titleX = endX;
            
        } else {    // 在右边
            
            endX = self.bounds.size.width - 10;
            endY = breakPointY;
            
            numberX = endX - numberWidth;
            titleX = endX - titleWidth;
        }
        
        
        if (i != 0) {
            
            // 当i!=0时，就需要计算位置总和(方法开始出的rect)与rect1(将进行绘制的位置)是否有重叠
            CGRect rect1 = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
            
            CGFloat margin = 0;
            
            if (CGRectIntersectsRect(rect, rect1)) {
                // 两个面积重叠
                // 三种情况
                // 1. 压上面
                // 2. 压下面
                // 3. 包含
                // 通过计算让面积重叠的情况消除
                if (CGRectContainsRect(rect, rect1)) {// 包含
                    
                    if (i % self.dataArray.count <= self.dataArray.count * 0.5 - 1) {
                        // 将要绘制的位置在总位置偏上
                        margin = CGRectGetMaxY(rect1) - rect.origin.y;
                        endY -= margin;
                    } else {
                        // 将要绘制的位置在总位置偏下
                        margin = CGRectGetMaxY(rect) - rect1.origin.y;
                        endY += margin;
                    }
                    
                    
                } else {    // 相交
                    
                    if (CGRectGetMaxY(rect1) > rect.origin.y && rect1.origin.y < rect.origin.y) { // 压在总位置上面
                        margin = CGRectGetMaxY(rect1) - rect.origin.y;
                        endY -= margin;
                        
                    } else if (rect1.origin.y < CGRectGetMaxY(rect) &&  CGRectGetMaxY(rect1) > CGRectGetMaxY(rect)) {  // 压总位置下面
                        margin = CGRectGetMaxY(rect) - rect1.origin.y;
                        endY += margin;
                    }
                    
                }
            }
            titleY = endY + 2;
            numberY = endY - numberHeight;
            
            
            // 通过计算得出的将要绘制的位置
            CGRect rect2 = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
            
            // 把新获得的rect和之前的rect合并
            if (numberX == rect.origin.x) {
                // 当两个位置在同一侧的时候才需要合并
                if (rect2.origin.y < rect.origin.y) {
                    rect = CGRectMake(rect.origin.x, rect2.origin.y, rect.size.width, rect.size.height + rect2.size.height);
                } else {
                    rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height + rect2.size.height);
                }
            }
            
        } else {
            rect = CGRectMake(numberX, numberY, numberWidth, titleY + titleHeight - numberY);
        }
        
        
        // 重新制定转折点
        if (endX == 10) {
            breakPointX = endX + lineWidth;
        } else {
            breakPointX = endX - lineWidth;
        }
        
        breakPointY = endY;
        
        //1.获取上下文
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        //2.绘制路径
        UIBezierPath *path = [UIBezierPath bezierPath];
        
        [path moveToPoint:CGPointMake(endX, endY)];
        
        [path addLineToPoint:CGPointMake(breakPointX, breakPointY)];
        
        [path addLineToPoint:CGPointMake(startX, startY)];
        
        CGContextSetLineWidth(ctx, 0.5);
        
        //设置颜色
        [color set];
        
        //3.把绘制的内容添加到上下文当中
        CGContextAddPath(ctx, path.CGPath);
        //4.把上下文的内容显示到View上(渲染到View的layer)(stroke fill)
        CGContextStrokePath(ctx);
        
        
        
        // 在终点处添加点(小圆点)
        // movePoint，让转折线指向小圆点中心
        CGFloat movePoint = -2.5;
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = color;
        [self addSubview:view];
        CGRect rect = view.frame;
        rect.size = CGSizeMake(5, 5);
        rect.origin = CGPointMake(startX + movePoint, startY - 2.5);
        view.frame = rect;
        view.layer.cornerRadius = 2.5;
        view.layer.masksToBounds = true;
        
        //指引线上面的数字
        [name drawInRect:CGRectMake(numberX, numberY, numberWidth, numberHeight) withAttributes:@{NSFontAttributeName:fontName, NSForegroundColorAttributeName:color,NSParagraphStyleAttributeName:paragraph}];
        
        // 指引线下面的title
        [number drawInRect:CGRectMake(titleX, titleY, titleWidth, titleHeight) withAttributes:@{NSFontAttributeName:fontName,NSForegroundColorAttributeName:color,NSParagraphStyleAttributeName:paragraph}];
        
    }
}

-(void)tapPieAction:(UITapGestureRecognizer *)tap
{
    CGPoint point = [tap locationInView:self];
    if (point.x < centerPoint.x * 2) {
        NSInteger num = [self PointOnArea:[tap locationInView:self]];        
        if (self.touchBlock) {
            self.touchBlock(self, num);
        }
    }
}

#pragma mark -- 根据点判断点击的位置在哪个扇形区
- (NSInteger)PointOnArea:(CGPoint)point {
    CGPoint p = [self PointAboutCenter:point];
    CGFloat radius = [self PointToRadiu:p];
    NSInteger num = [self RadiusToTag:radius];
    return num;
}

- (CGPoint)PointAboutCenter:(CGPoint)point {
    CGPoint  p;
    p.x = point.x - centerPoint.x;
    p.y = point.y - centerPoint.y;
    return p;
}

- (CGFloat)PointToRadiu:(CGPoint)point {
    float r = atan(point.y/point.x);
    
    CGFloat radius = TO_RADIUS(r);
    if (point.x < 0 && point.y > 0) {
        radius = 180 + radius;
    } else if (point.x < 0 && point.y < 0) {
        radius += 180;
    } else if (point.x >0 && point.y <0) {
        radius = 360 + radius;
    }
    return radius;
}

- (NSInteger)RadiusToTag:(CGFloat)radius {
    for (int i = 0; i < [self createRadiusVauleArray].count; i++) {
        RadiusRange *r = [self createRadiusVauleArray][i];
        if (radius >= r.start && radius <= r.end) {
            return i;
        }
    }
    return -1;
}

-(NSMutableArray *)createRadiusVauleArray
{
    NSMutableArray *totalArr = [[NSMutableArray alloc] init];
    NSMutableArray *rArray = [[NSMutableArray alloc] init];
    for (int j = 0; j < self.dataArray.count; j++)
    {
        PooPieViewModel *model = self.dataArray[j];
        [totalArr addObject:model.value];
    }
    
    CGFloat end = 0;
    for (int i = 0; i < self.dataArray.count; i++) {
        RadiusRange *r = [[RadiusRange alloc] init];
        PooPieViewModel *model = self.dataArray[i];
        CGFloat percent = [model.value floatValue]/[[totalArr valueForKeyPath:@"@sum.floatValue"] floatValue];

        if (i == 0) {
            r.start = 0;
            r.end = percent * 360;
            [rArray addObject:r];
            end = r.end;
        }
        else
        {
            r.start = end;
            r.end = r.start + percent * 360;
            [rArray addObject:r];
            end = r.end;
        }
    }
    return rArray;
}

@end

@implementation RadiusRange
@end

@implementation PooPieCenterView

- (instancetype)initWithFrame:(CGRect)frame centerLabelFont:(UIFont *)cFont;
{
    
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.4];
        
        UIView *centerView = [[UIView alloc] init];
        centerView.backgroundColor = [UIColor whiteColor];
        [self addSubview:centerView];
        self.centerView = centerView;
        
        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.textColor = kRGBAColor(51, 51, 51, 1);
        nameLabel.font = cFont;
        
        nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel = nameLabel;
        [centerView addSubview:nameLabel];
    }
    
    return self;
}


- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    self.layer.cornerRadius = self.width * 0.5;
    self.layer.masksToBounds = true;
    
    self.centerView.frame = CGRectMake(6, 6, self.width - 6 * 2, self.height - 6 * 2);
    self.centerView.layer.cornerRadius = self.centerView.width * 0.5;
    self.centerView.layer.masksToBounds = true;
    self.nameLabel.frame = self.centerView.bounds;
}

@end

@implementation PooPieViewModel
@end
