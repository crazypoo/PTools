//
//  PooTagsLabel.h
//  XMNiao_Shop
//
//  Created by MYX on 2017/3/16.
//  Copyright © 2017年 邓杰豪. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PooTagsLabel;

typedef void(^tagBtnClicked)(PooTagsLabel *aTagsView, UIButton *sender, NSInteger tag);

@interface PooTagsLabelConfig : NSObject

@property (nonatomic) CGFloat itemHerMargin;            //item之间的左右间距
@property (nonatomic) CGFloat itemVerMargin;            //item之间的上下间距
@property (nonatomic) CGFloat itemHeight;               //item的高度
@property (nonatomic) CGFloat itemContentEdgs;          //item标题距左右边缘的距离
@property (nonatomic) CGFloat topBottomSpace;           //最顶部和最底部的item距离俯视图顶部和底部的距离(无间距时可设为0.1)

@property (nonatomic) CGFloat fontSize;                     //字体大小  默认12
@property (nonatomic,strong) UIColor *normalTitleColor;
@property (nonatomic,strong) UIColor *selectedTitleColor;
@property (nonatomic,strong) UIColor *backgroundColor;
@property (nonatomic,strong) NSString *normalBgImage;
@property (nonatomic,strong) NSString *selectedBgImage;


//是否有边框  默认没有边框
@property (nonatomic) BOOL hasBorder;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) UIColor *borderColor;

//是否可以选中默认为NO (YES时为单选)
@property (nonatomic) BOOL isCanSelected;
@property (nonatomic) BOOL isCanCancelSelected; //是否可以取消选中

@property (nonatomic) BOOL isMulti;
@property (nonatomic,copy) NSString *singleSelectedTitle;     //单个选中对应的标题(初始化时默认选中的)
@property (nonatomic,copy) NSArray *selectedDefaultTags;      //多个选中对应的标题数组(初始化时默认选中的)



@end



@interface PooTagsLabel : UIView

///点击回调
@property (nonatomic,copy) tagBtnClicked tagBtnClickedBlock;

@property (nonatomic,strong) UIImageView *bgImageView;
///对应单选 当前选中的tag按钮
@property (nonatomic,strong) UIButton *selectedBtn;
//多个选中对应的标题数组
@property (nonatomic,copy) NSMutableArray *multiSelectedTags;
/*
 必须给父视图设置一个宽度
 */
-(instancetype)initWithFrame:(CGRect)frame tagsArray:(NSArray *)tagsArr config:(PooTagsLabelConfig *)config wihtSection:(NSInteger)sectionIndex;

- (CGFloat)heighttagsArray:(NSArray *)tagsArr config:(PooTagsLabelConfig *)config;
@end
