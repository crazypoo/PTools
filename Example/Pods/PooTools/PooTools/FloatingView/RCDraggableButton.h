//
//  RCDraggableButton.h
//  RCDraggableButton
//
//  Created by Looping (www.looping@gmail.com) on 14-2-8.
//  Copyright (c) 2014 RidgeCorn (https://github.com/RidgeCorn).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#define RCDRAGGABLEBUTTON_VERSION @"0.4"

@interface RCDraggableButton : UIButton {
    BOOL _isDragging;
    BOOL _singleTapCanceled;
    BOOL _skipTapEventOnce;
    BOOL _willBeRemoved;
    BOOL _draggableAfterLongPress;
    BOOL _isRecordingDraggingPathEnabled;
    
    CGPoint _touchBeginPoint;
    CGPoint _moveBeginPoint;
    
    UIBezierPath *_draggingPath;
    
    NSMutableArray *_traceButtons;
    NSTimer *_traceDismissTimer;
}
@property (nonatomic, strong) NSTimer *autoAddTraceButtonTimer;
@property (nonatomic) BOOL isRecordingDraggingPathEnabled;

@property (nonatomic) BOOL draggable;
@property (nonatomic) BOOL autoDocking;
@property (nonatomic) BOOL isTraceEnabled;
@property (nonatomic) BOOL dragOutOfBoundsEnabled;

@property (nonatomic) CGPoint dockPoint;
@property (nonatomic) CGFloat limitedDistance;

@property (nonatomic, copy) void(^longPressBlock)(RCDraggableButton *button);
@property (nonatomic, copy) void(^longPressEndedBlock)(RCDraggableButton *button);

@property (nonatomic, copy) void(^tapBlock)(RCDraggableButton *button);
@property (nonatomic, copy) void(^doubleTapBlock)(RCDraggableButton *button);

@property (nonatomic, copy) void(^draggingBlock)(RCDraggableButton *button);
@property (nonatomic, copy) void(^dragEndedBlock)(RCDraggableButton *button);
@property (nonatomic, copy) void(^dragCancelledBlock)(RCDraggableButton *button);

@property (nonatomic, copy) void(^autoDockingBlock)(RCDraggableButton *button);
@property (nonatomic, copy) void(^autoDockEndedBlock)(RCDraggableButton *button);

@property (nonatomic, copy) void(^layerConfigBlock)(RCDraggableButton *button);

@property (nonatomic, copy) void(^willBeRemovedBlock)(RCDraggableButton *button);

- (id)initInView:(id)view WithFrame:(CGRect)frame;

- (BOOL)isDragging;

+ (NSString *)version;

+ (NSArray *)itemsInView:(id)view;
- (BOOL)isInView:(id)view;

- (BOOL)isInsideRect:(CGRect)rect;
- (BOOL)isIntersectsRect:(CGRect)rect;
- (BOOL)isCrossedRect:(CGRect)rect;

- (void)cleanAllCodeBlocks;

+ (void)removeAllFromView:(id)view;

+ (void)removeFromView:(id)view withTag:(NSInteger)tag;
+ (void)removeFromView:(id)view withTags:(NSArray *)tags;

+ (void)removeAllFromView:(id)view insideRect:(CGRect)rect;
- (void)removeFromSuperviewInsideRect:(CGRect)rect;

+ (void)removeAllFromView:(id)view intersectsRect:(CGRect)rect;
- (void)removeFromSuperviewIntersectsRect:(CGRect)rect;

+ (void)removeAllFromView:(id)view crossedRect:(CGRect)rect;
- (void)removeFromSuperviewCrossedRect:(CGRect)rect;

+ (void)allInView:(id)view moveToPoint:(CGPoint)point animatedWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options completion:(void (^)(void))completion;
+ (void)inView:(id)view withTag:(NSInteger)tag moveToPoint:(CGPoint)point animatedWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options completion:(void (^)(void))completion;
+ (void)inView:(id)view withTags:(NSArray *)tags moveToPoint:(CGPoint)point animatedWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options completion:(void (^)(void))completion;
- (void)moveToPoint:(CGPoint)point animatedWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options completion:(void (^)(void))completion;

+ (void)allInView:(id)view moveToPoint:(CGPoint)point;
+ (void)inView:(id)view withTag:(NSInteger)tag moveToPoint:(CGPoint)point;
+ (void)inView:(id)view withTags:(NSArray *)tags moveToPoint:(CGPoint)point;
- (void)moveToPoint:(CGPoint)point;

- (CGFloat)distanceFromPoint:(CGPoint)point;

- (CGFloat)distanceFromRect:(CGRect)rect;

- (void)setDraggableAfterLongPress:(BOOL)draggableAfterLongPress;

- (void)startRecordDraggingPath;
- (UIBezierPath *)stopRecordDraggingPath;
- (BOOL)isRecordingDraggingPath;
- (UIBezierPath *)draggingPath;

- (BOOL)checkIfExceedingLimitedDistanceThenFixIt:(BOOL)fixIt;
- (BOOL)checkIfOutOfBoundsThenFixIt:(BOOL)fixIt;

@end
